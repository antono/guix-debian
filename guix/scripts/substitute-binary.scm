;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Ludovic Courtès <ludo@gnu.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix scripts substitute-binary)
  #:use-module (guix ui)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix config)
  #:use-module (guix records)
  #:use-module (guix nar)
  #:use-module ((guix build utils) #:select (mkdir-p))
  #:use-module ((guix build download)
                #:select (progress-proc uri-abbreviation))
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:use-module (ice-9 threads)
  #:use-module (ice-9 format)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 binary-ports)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-19)
  #:use-module (srfi srfi-26)
  #:use-module (web uri)
  #:use-module (guix http-client)
  #:export (guix-substitute-binary))

;;; Comment:
;;;
;;; This is the "binary substituter".  It is invoked by the daemon do check
;;; for the existence of available "substitutes" (pre-built binaries), and to
;;; actually use them as a substitute to building things locally.
;;;
;;; If possible, substitute a binary for the requested store path, using a Nix
;;; "binary cache".  This program implements the Nix "substituter" protocol.
;;;
;;; Code:

(define %narinfo-cache-directory
  ;; A local cache of narinfos, to avoid going to the network.
  (or (and=> (getenv "XDG_CACHE_HOME")
             (cut string-append <> "/guix/substitute-binary"))
      (string-append %state-directory "/substitute-binary/cache")))

(define %narinfo-ttl
  ;; Number of seconds during which cached narinfo lookups are considered
  ;; valid.
  (* 24 3600))

(define %narinfo-negative-ttl
  ;; Likewise, but for negative lookups---i.e., cached lookup failures.
  (* 3 3600))

(define %narinfo-expired-cache-entry-removal-delay
  ;; How often we want to remove files corresponding to expired cache entries.
  (* 7 24 3600))

(define (with-atomic-file-output file proc)
  "Call PROC with an output port for the file that is going to replace FILE.
Upon success, FILE is atomically replaced by what has been written to the
output port, and PROC's result is returned."
  (let* ((template (string-append file ".XXXXXX"))
         (out      (mkstemp! template)))
    (with-throw-handler #t
      (lambda ()
        (let ((result (proc out)))
          (close out)
          (rename-file template file)
          result))
      (lambda (key . args)
        (false-if-exception (delete-file template))))))

;; In Guile 2.0.9, `regexp-exec' is thread-unsafe, so work around it.
;; See <http://bugs.gnu.org/14404>.
(set! regexp-exec
      (let ((real regexp-exec)
            (lock (make-mutex)))
        (lambda args
          (with-mutex lock
            (apply real args)))))

(define fields->alist
  ;; The narinfo format is really just like recutils.
  recutils->alist)

(define %fetch-timeout
  ;; Number of seconds after which networking is considered "slow".
  5)

(define %random-state
  (seed->random-state (+ (ash (cdr (gettimeofday)) 32) (getpid))))

(define-syntax-rule (with-timeout duration handler body ...)
  "Run BODY; when DURATION seconds have expired, call HANDLER, and run BODY
again."
  (begin
    (sigaction SIGALRM
      (lambda (signum)
        (sigaction SIGALRM SIG_DFL)
        handler))
    (alarm duration)
    (call-with-values
        (lambda ()
          (let try ()
            (catch 'system-error
              (lambda ()
                body ...)
              (lambda args
                ;; The SIGALRM triggers EINTR, because of the bug at
                ;; <http://lists.gnu.org/archive/html/guile-devel/2013-06/msg00050.html>.
                ;; When that happens, try again.  Note: SA_RESTART cannot be
                ;; used because of <http://bugs.gnu.org/14640>.
                (if (= EINTR (system-error-errno args))
                    (begin
                      ;; Wait a little to avoid bursts.
                      (usleep (random 3000000 %random-state))
                      (try))
                    (apply throw args))))))
      (lambda result
        (alarm 0)
        (sigaction SIGALRM SIG_DFL)
        (apply values result)))))

(define* (fetch uri #:key (buffered? #t) (timeout? #t))
  "Return a binary input port to URI and the number of bytes it's expected to
provide."
  (case (uri-scheme uri)
    ((file)
     (let ((port (open-file (uri-path uri)
                            (if buffered? "rb" "r0b"))))
       (values port (stat:size (stat port)))))
    ((http)
     ;; On Guile 2.0.5, `http-fetch' fetches the whole thing at once.  So
     ;; honor TIMEOUT? to disable the timeout when fetching a nar.
     ;;
     ;; Test this with:
     ;;   sudo tc qdisc add dev eth0 root netem delay 1500ms
     ;; and then cancel with:
     ;;   sudo tc qdisc del dev eth0 root
     (let ((port #f))
       (with-timeout (if (or timeout? (guile-version>? "2.0.5"))
                         %fetch-timeout
                         0)
         (begin
           (warning (_ "while fetching ~a: server is unresponsive~%")
                    (uri->string uri))
           (warning (_ "try `--no-substitutes' if the problem persists~%"))
           (when port
             (close-port port)))
         (begin
           (set! port (open-socket-for-uri uri #:buffered? buffered?))
           (http-fetch uri #:text? #f #:port port)))))))

(define-record-type <cache>
  (%make-cache url store-directory wants-mass-query?)
  cache?
  (url               cache-url)
  (store-directory   cache-store-directory)
  (wants-mass-query? cache-wants-mass-query?))

(define (open-cache url)
  "Open the binary cache at URL.  Return a <cache> object on success, or #f on
failure."
  (define (download-cache-info url)
    ;; Download the `nix-cache-info' from URL, and return its contents as an
    ;; list of key/value pairs.
    (and=> (false-if-exception (fetch (string->uri url)))
           fields->alist))

  (and=> (download-cache-info (string-append url "/nix-cache-info"))
         (lambda (properties)
           (alist->record properties
                          (cut %make-cache url <...>)
                          '("StoreDir" "WantMassQuery")))))

(define-record-type <narinfo>
  (%make-narinfo path uri compression file-hash file-size nar-hash nar-size
                 references deriver system)
  narinfo?
  (path         narinfo-path)
  (uri          narinfo-uri)
  (compression  narinfo-compression)
  (file-hash    narinfo-file-hash)
  (file-size    narinfo-file-size)
  (nar-hash     narinfo-hash)
  (nar-size     narinfo-size)
  (references   narinfo-references)
  (deriver      narinfo-deriver)
  (system       narinfo-system))

(define (narinfo-maker cache-url)
  "Return a narinfo constructor for narinfos originating from CACHE-URL."
  (lambda (path url compression file-hash file-size nar-hash nar-size
                references deriver system)
    "Return a new <narinfo> object."
    (%make-narinfo path

                   ;; Handle the case where URL is a relative URL.
                   (or (string->uri url)
                       (string->uri (string-append cache-url "/" url)))

                   compression file-hash
                   (and=> file-size string->number)
                   nar-hash
                   (and=> nar-size string->number)
                   (string-tokenize references)
                   (match deriver
                     ((or #f "") #f)
                     (_ deriver))
                   system)))

(define* (read-narinfo port #:optional url)
  "Read a narinfo from PORT in its standard external form.  If URL is true, it
must be a string used to build full URIs from relative URIs found while
reading PORT."
  (alist->record (fields->alist port)
                 (narinfo-maker url)
                 '("StorePath" "URL" "Compression"
                   "FileHash" "FileSize" "NarHash" "NarSize"
                   "References" "Deriver" "System")))

(define (write-narinfo narinfo port)
  "Write NARINFO to PORT."
  (define (empty-string-if-false x)
    (or x ""))

  (define (number-or-empty-string x)
    (if (number? x)
        (number->string x)
        ""))

  (object->fields narinfo
                  `(("StorePath" . ,narinfo-path)
                    ("URL" . ,(compose uri->string narinfo-uri))
                    ("Compression" . ,narinfo-compression)
                    ("FileHash" . ,(compose empty-string-if-false
                                            narinfo-file-hash))
                    ("FileSize" . ,(compose number-or-empty-string
                                            narinfo-file-size))
                    ("NarHash" . ,(compose empty-string-if-false
                                           narinfo-hash))
                    ("NarSize" . ,(compose number-or-empty-string
                                           narinfo-size))
                    ("References" . ,(compose string-join narinfo-references))
                    ("Deriver" . ,(compose empty-string-if-false
                                           narinfo-deriver))
                    ("System" . ,narinfo-system))
                  port))

(define (narinfo->string narinfo)
  "Return the external representation of NARINFO."
  (call-with-output-string (cut write-narinfo narinfo <>)))

(define (string->narinfo str)
  "Return the narinfo represented by STR."
  (call-with-input-string str (cut read-narinfo <>)))

(define (fetch-narinfo cache path)
  "Return the <narinfo> record for PATH, or #f if CACHE does not hold PATH."
  (define (download url)
    ;; Download the .narinfo from URL, and return its contents as a list of
    ;; key/value pairs.
    (false-if-exception (fetch (string->uri url))))

  (and (string=? (cache-store-directory cache) (%store-prefix))
       (and=> (download (string-append (cache-url cache) "/"
                                       (store-path-hash-part path)
                                       ".narinfo"))
              (cute read-narinfo <> (cache-url cache)))))

(define (obsolete? date now ttl)
  "Return #t if DATE is obsolete compared to NOW + TTL seconds."
  (time>? (subtract-duration now (make-time time-duration 0 ttl))
          (make-time time-monotonic 0 date)))

(define (lookup-narinfo cache path)
  "Check locally if we have valid info about PATH, otherwise go to CACHE and
check what it has."
  (define now
    (current-time time-monotonic))

  (define cache-file
    (string-append %narinfo-cache-directory "/"
                   (store-path-hash-part path)))

  (define (cache-entry narinfo)
    `(narinfo (version 0)
              (date ,(time-second now))
              (value ,(and=> narinfo narinfo->string))))

  (let*-values (((valid? cached)
                 (catch 'system-error
                   (lambda ()
                     (call-with-input-file cache-file
                       (lambda (p)
                         (match (read p)
                           (('narinfo ('version 0) ('date date)
                                      ('value #f))
                            ;; A cached negative lookup.
                            (if (obsolete? date now %narinfo-negative-ttl)
                                (values #f #f)
                                (values #t #f)))
                           (('narinfo ('version 0) ('date date)
                                      ('value value))
                            ;; A cached positive lookup
                            (if (obsolete? date now %narinfo-ttl)
                                (values #f #f)
                                (values #t (string->narinfo value))))))))
                   (lambda _
                     (values #f #f)))))
    (if valid?
        cached                                    ; including negative caches
        (let* ((cache   (force cache))
               (narinfo (and cache (fetch-narinfo cache path))))
          ;; Cache NARINFO only when CACHE was actually accessible.  This
          ;; avoids caching negative hits when in fact we just lacked network
          ;; access.
          (when cache
            (with-atomic-file-output cache-file
              (lambda (out)
                (write (cache-entry narinfo) out))))
          narinfo))))

(define (remove-expired-cached-narinfos)
  "Remove expired narinfo entries from the cache.  The sole purpose of this
function is to make sure `%narinfo-cache-directory' doesn't grow
indefinitely."
  (define now
    (current-time time-monotonic))

  (define (expired? file)
    (catch 'system-error
      (lambda ()
        (call-with-input-file file
          (lambda (port)
            (match (read port)
              (('narinfo ('version 0) ('date date)
                         ('value #f))
               (obsolete? date now %narinfo-negative-ttl))
              (('narinfo ('version 0) ('date date)
                         ('value _))
               (obsolete? date now %narinfo-ttl))
              (_ #t)))))
      (lambda args
        ;; FILE may have been deleted.
        #t)))

  (for-each (lambda (file)
              (let ((file (string-append %narinfo-cache-directory
                                         "/" file)))
                (when (expired? file)
                  ;; Wrap in `false-if-exception' because FILE might have been
                  ;; deleted in the meantime (TOCTTOU).
                  (false-if-exception (delete-file file)))))
            (scandir %narinfo-cache-directory
                     (lambda (file)
                       (= (string-length file) 32)))))

(define (maybe-remove-expired-cached-narinfo)
  "Remove expired narinfo entries from the cache if deemed necessary."
  (define now
    (current-time time-monotonic))

  (define expiry-file
    (string-append %narinfo-cache-directory "/last-expiry-cleanup"))

  (define last-expiry-date
    (or (false-if-exception
         (call-with-input-file expiry-file read))
        0))

  (when (obsolete? last-expiry-date now %narinfo-expired-cache-entry-removal-delay)
    (remove-expired-cached-narinfos)
    (call-with-output-file expiry-file
      (cute write (time-second now) <>))))

(define (decompressed-port compression input)
  "Return an input port where INPUT is decompressed according to COMPRESSION,
along with a list of PIDs to wait for."
  (match compression
    ("none"  (values input '()))
    ("bzip2" (filtered-port `(,%bzip2 "-dc") input))
    ("xz"    (filtered-port `(,%xz "-dc") input))
    ("gzip"  (filtered-port `(,%gzip "-dc") input))
    (else    (error "unsupported compression scheme" compression))))

(define (progress-report-port report-progress port)
  "Return a port that calls REPORT-PROGRESS every time something is read from
PORT.  REPORT-PROGRESS is a two-argument procedure such as that returned by
`progress-proc'."
  (define total 0)
  (define (read! bv start count)
    (let ((n (match (get-bytevector-n! port bv start count)
               ((? eof-object?) 0)
               (x x))))
      (set! total (+ total n))
      (report-progress total (const n))
      ;; XXX: We're not in control, so we always return anyway.
      n))

  ;; Since `http-fetch' in Guile 2.0.5 returns all the data once it's done,
  ;; don't pretend to report any progress in that case.
  (if (guile-version>? "2.0.5")
      (make-custom-binary-input-port "progress-port-proc"
                                     read! #f #f
                                     (cut close-port port))
      (begin
        (format (current-error-port) (_ "Downloading, please wait...~%"))
        (format (current-error-port)
                (_ "(Please consider upgrading Guile to get proper progress report.)~%"))
        port)))

(define %cache-url
  (or (getenv "GUIX_BINARY_SUBSTITUTE_URL")
      "http://hydra.gnu.org"))

(define-syntax with-networking
  (syntax-rules ()
    "Catch DNS lookup errors and gracefully exit."
    ;; Note: no attempt is made to catch other networking errors, because DNS
    ;; lookup errors are typically the first one, and because other errors are
    ;; a subset of `system-error', which is harder to filter.
    ((_ exp ...)
     (catch 'getaddrinfo-error
       (lambda () exp ...)
       (lambda (key error)
         (leave (_ "host name lookup error: ~a~%")
                (gai-strerror error)))))))


;;;
;;; Help.
;;;

(define (show-help)
  (display (_ "Usage: guix substitute-binary [OPTION]...
Internal tool to substitute a pre-built binary to a local build.\n"))
  (display (_ "
      --query            report on the availability of substitutes for the
                         store file names passed on the standard input"))
  (display (_ "
      --substitute STORE-FILE DESTINATION
                         download STORE-FILE and store it as a Nar in file
                         DESTINATION"))
  (newline)
  (display (_ "
  -h, --help             display this help and exit"))
  (display (_ "
  -V, --version          display version information and exit"))
  (newline)
  (show-bug-report-information))



;;;
;;; Entry point.
;;;

(define (guix-substitute-binary . args)
  "Implement the build daemon's substituter protocol."
  (mkdir-p %narinfo-cache-directory)
  (maybe-remove-expired-cached-narinfo)
  (with-networking
   (match args
     (("--query")
      (let ((cache (delay (open-cache %cache-url))))
        (let loop ((command (read-line)))
          (or (eof-object? command)
              (begin
                (match (string-tokenize command)
                  (("have" paths ..1)
                   ;; Return the subset of PATHS available in CACHE.
                   (let ((substitutable
                          (if cache
                              (par-map (cut lookup-narinfo cache <>)
                                       paths)
                              '())))
                     (for-each (lambda (narinfo)
                                 (when narinfo
                                   (format #t "~a~%" (narinfo-path narinfo))))
                               (filter narinfo? substitutable))
                     (newline)))
                  (("info" paths ..1)
                   ;; Reply info about PATHS if it's in CACHE.
                   (let ((substitutable
                          (if cache
                              (par-map (cut lookup-narinfo cache <>)
                                       paths)
                              '())))
                     (for-each (lambda (narinfo)
                                 (format #t "~a\n~a\n~a\n"
                                         (narinfo-path narinfo)
                                         (or (and=> (narinfo-deriver narinfo)
                                                    (cute string-append
                                                          (%store-prefix) "/"
                                                          <>))
                                             "")
                                         (length (narinfo-references narinfo)))
                                 (for-each (cute format #t "~a/~a~%"
                                                 (%store-prefix) <>)
                                           (narinfo-references narinfo))
                                 (format #t "~a\n~a\n"
                                         (or (narinfo-file-size narinfo) 0)
                                         (or (narinfo-size narinfo) 0)))
                               (filter narinfo? substitutable))
                     (newline)))
                  (wtf
                   (error "unknown `--query' command" wtf)))
                (loop (read-line)))))))
     (("--substitute" store-path destination)
      ;; Download STORE-PATH and add store it as a Nar in file DESTINATION.
      (let* ((cache   (delay (open-cache %cache-url)))
             (narinfo (lookup-narinfo cache store-path))
             (uri     (narinfo-uri narinfo)))
        ;; Tell the daemon what the expected hash of the Nar itself is.
        (format #t "~a~%" (narinfo-hash narinfo))

        (format (current-error-port) "downloading `~a' from `~a'~:[~*~; (~,1f MiB installed)~]...~%"
                store-path (uri->string uri)

                ;; Use the Nar size as an estimate of the installed size.
                (narinfo-size narinfo)
                (and=> (narinfo-size narinfo)
                       (cute / <> (expt 2. 20))))
        (let*-values (((raw download-size)
                       ;; Note that Hydra currently generates Nars on the fly
                       ;; and doesn't specify a Content-Length, so
                       ;; DOWNLOAD-SIZE is #f in practice.
                       (fetch uri #:buffered? #f #:timeout? #f))
                      ((progress)
                       (let* ((comp     (narinfo-compression narinfo))
                              (dl-size  (or download-size
                                            (and (equal? comp "none")
                                                 (narinfo-size narinfo))))
                              (progress (progress-proc (uri-abbreviation uri)
                                                       dl-size
                                                       (current-error-port))))
                         (progress-report-port progress raw)))
                      ((input pids)
                       (decompressed-port (narinfo-compression narinfo)
                                          progress)))
          ;; Unpack the Nar at INPUT into DESTINATION.
          (restore-file input destination)
          (every (compose zero? cdr waitpid) pids))))
     (("--version")
      (show-version-and-exit "guix substitute-binary"))
     (("--help")
      (show-help))
     (opts
      (leave (_ "~a: unrecognized options~%") opts)))))


;;; Local Variables:
;;; eval: (put 'with-atomic-file-output 'scheme-indent-function 1)
;;; eval: (put 'with-timeout 'scheme-indent-function 1)
;;; End:

;;; substitute-binary.scm ends here
