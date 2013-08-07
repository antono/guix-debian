;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2013 Nikita Karetnikov <nikita@karetnikov.org>
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

(define-module (guix ui)
  #:use-module (guix utils)
  #:use-module (guix store)
  #:use-module (guix config)
  #:use-module (guix packages)
  #:use-module (guix build-system)
  #:use-module (guix derivations)
  #:use-module ((guix licenses) #:select (license? license-name))
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-37)
  #:autoload   (ice-9 ftw)  (scandir)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:export (_
            N_
            leave
            show-version-and-exit
            show-bug-report-information
            string->number*
            show-what-to-build
            call-with-error-handling
            with-error-handling
            read/eval-package-expression
            location->string
            switch-symlinks
            config-directory
            fill-paragraph
            string->recutils
            package->recutils
            args-fold*
            run-guix-command
            program-name
            guix-warning-port
            warning
            guix-main))

;;; Commentary:
;;;
;;; User interface facilities for command-line tools.
;;;
;;; Code:

(define %gettext-domain
  "guix")

(define _ (cut gettext <> %gettext-domain))
(define N_ (cut ngettext <> <> <> %gettext-domain))

(define-syntax-rule (define-diagnostic name prefix)
  "Create a diagnostic macro (i.e., NAME), which will prepend PREFIX to all
messages."
  (define-syntax name
    (lambda (x)
      (define (augmented-format-string fmt)
        (string-append "~:[~*~;guix ~a: ~]~a" (syntax->datum fmt)))

      (syntax-case x ()
        ((name (underscore fmt) args (... ...))
         (and (string? (syntax->datum #'fmt))
              (free-identifier=? #'underscore #'_))
         (with-syntax ((fmt*   (augmented-format-string #'fmt))
                       (prefix (datum->syntax x prefix)))
           #'(format (guix-warning-port) (gettext fmt*)
                     (program-name) (program-name) prefix
                     args (... ...))))
        ((name (N-underscore singular plural n) args (... ...))
         (and (string? (syntax->datum #'singular))
              (string? (syntax->datum #'plural))
              (free-identifier=? #'N-underscore #'N_))
         (with-syntax ((s      (augmented-format-string #'singular))
                       (p      (augmented-format-string #'plural))
                       (prefix (datum->syntax x prefix)))
           #'(format (guix-warning-port)
                     (ngettext s p n %gettext-domain)
                     (program-name) (program-name) prefix
                     args (... ...))))))))

(define-diagnostic warning "warning: ") ; emit a warning

(define-diagnostic report-error "error: ")
(define-syntax-rule (leave args ...)
  "Emit an error message and exit."
  (begin
    (report-error args ...)
    (exit 1)))

(define (install-locale)
  "Install the current locale settings."
  (catch 'system-error
    (lambda _
      (setlocale LC_ALL ""))
    (lambda args
      (warning (_ "failed to install locale: ~a~%")
               (strerror (system-error-errno args))))))

(define (initialize-guix)
  "Perform the usual initialization for stand-alone Guix commands."
  (install-locale)
  (textdomain "guix")

  ;; Ignore SIGPIPE.  If the daemon closes the connection, we prefer to be
  ;; notified via an EPIPE later.
  (sigaction SIGPIPE SIG_IGN)

  (setvbuf (current-output-port) _IOLBF)
  (setvbuf (current-error-port) _IOLBF))

(define* (show-version-and-exit #:optional (command (car (command-line))))
  "Display version information for COMMAND and `(exit 0)'."
  (simple-format #t "~a (~a) ~a~%"
                 command %guix-package-name %guix-version)
  (exit 0))

(define (show-bug-report-information)
  (format #t (_ "
Report bugs to: ~a.") %guix-bug-report-address)
  (format #t (_ "
~a home page: <~a>") %guix-package-name %guix-home-page-url)
  (display (_ "
General help using GNU software: <http://www.gnu.org/gethelp/>"))
  (newline))

(define (string->number* str)
  "Like `string->number', but error out with an error message on failure."
  (or (string->number str)
      (leave (_ "~a: invalid number~%") str)))

(define (call-with-error-handling thunk)
  "Call THUNK within a user-friendly error handler."
  (guard (c ((package-input-error? c)
             (let* ((package  (package-error-package c))
                    (input    (package-error-invalid-input c))
                    (location (package-location package))
                    (file     (location-file location))
                    (line     (location-line location))
                    (column   (location-column location)))
               (leave (_ "~a:~a:~a: package `~a' has an invalid input: ~s~%")
                      file line column
                      (package-full-name package) input)))
            ((package-cross-build-system-error? c)
             (let* ((package (package-error-package c))
                    (loc     (package-location package))
                    (system  (package-build-system package)))
               (leave (_ "~a: ~a: build system `~a' does not support cross builds~%")
                      (location->string loc)
                      (package-full-name package)
                      (build-system-name system))))
            ((nix-connection-error? c)
             (leave (_ "failed to connect to `~a': ~a~%")
                    (nix-connection-error-file c)
                    (strerror (nix-connection-error-code c))))
            ((nix-protocol-error? c)
             ;; FIXME: Server-provided error messages aren't i18n'd.
             (leave (_ "build failed: ~a~%")
                    (nix-protocol-error-message c))))
    ;; Catch EPIPE and the likes.
    (catch 'system-error
      thunk
      (lambda args
        (leave (_ "~a~%")
               (strerror (system-error-errno args)))))))

(define (read/eval-package-expression str)
  "Read and evaluate STR and return the package it refers to, or exit an
error."
  (let ((exp (catch #t
               (lambda ()
                 (call-with-input-string str read))
               (lambda args
                 (leave (_ "failed to read expression ~s: ~s~%")
                        str args)))))
    (let ((p (catch #t
               (lambda ()
                 (eval exp the-scm-module))
               (lambda args
                 (leave (_ "failed to evaluate expression `~a': ~s~%")
                        exp args)))))
      (if (package? p)
          p
          (leave (_ "expression `~s' does not evaluate to a package~%")
                 exp)))))

(define* (show-what-to-build store drv
                             #:key dry-run? (use-substitutes? #t))
  "Show what will or would (depending on DRY-RUN?) be built in realizing the
derivations listed in DRV.  Return #t if there's something to build, #f
otherwise.  When USE-SUBSTITUTES?, check and report what is prerequisites are
available for download."
  (let*-values (((build download)
                 (fold2 (lambda (drv-path build download)
                          (let ((drv (call-with-input-file drv-path
                                       read-derivation)))
                            (let-values (((b d)
                                          (derivation-prerequisites-to-build
                                           store drv
                                           #:use-substitutes?
                                           use-substitutes?)))
                              (values (append b build)
                                      (append d download)))))
                        '() '()
                        drv))
                ((build)                          ; add the DRV themselves
                 (delete-duplicates
                  (append (remove (compose (lambda (out)
                                             (or (valid-path? store out)
                                                 (and use-substitutes?
                                                      (has-substitutes? store
                                                                        out))))
                                           derivation-path->output-path)
                                  drv)
                          (map derivation-input-path build))))
                ((download)                   ; add the references of DOWNLOAD
                 (if use-substitutes?
                     (delete-duplicates
                      (append download
                              (remove (cut valid-path? store <>)
                                      (append-map
                                       substitutable-references
                                       (substitutable-path-info store
                                                                download)))))
                     download)))
    (if dry-run?
        (begin
          (format (current-error-port)
                  (N_ "~:[The following derivation would be built:~%~{   ~a~%~}~;~]"
                      "~:[The following derivations would be built:~%~{   ~a~%~}~;~]"
                      (length build))
                  (null? build) build)
          (format (current-error-port)
                  (N_ "~:[The following file would be downloaded:~%~{   ~a~%~}~;~]"
                      "~:[The following files would be downloaded:~%~{   ~a~%~}~;~]"
                      (length download))
                  (null? download) download))
        (begin
          (format (current-error-port)
                  (N_ "~:[The following derivation will be built:~%~{   ~a~%~}~;~]"
                      "~:[The following derivations will be built:~%~{   ~a~%~}~;~]"
                      (length build))
                  (null? build) build)
          (format (current-error-port)
                  (N_ "~:[The following file will be downloaded:~%~{   ~a~%~}~;~]"
                      "~:[The following files will be downloaded:~%~{   ~a~%~}~;~]"
                      (length download))
                  (null? download) download)))
    (pair? build)))

(define-syntax with-error-handling
  (syntax-rules ()
    "Run BODY within a user-friendly error condition handler."
    ((_ body ...)
     (call-with-error-handling
      (lambda ()
        body ...)))))

(define (location->string loc)
  "Return a human-friendly, GNU-standard representation of LOC."
  (match loc
    (#f (_ "<unknown location>"))
    (($ <location> file line column)
     (format #f "~a:~a:~a" file line column))))

(define (switch-symlinks link target)
  "Atomically switch LINK, a symbolic link, to point to TARGET.  Works
both when LINK already exists and when it does not."
  (let ((pivot (string-append link ".new")))
    (symlink target pivot)
    (rename-file pivot link)))

(define (config-directory)
  "Return the name of the configuration directory, after making sure that it
exists.  Honor the XDG specs,
<http://standards.freedesktop.org/basedir-spec/basedir-spec-latest.html>."
  (let ((dir (and=> (or (getenv "XDG_CONFIG_HOME")
                        (and=> (getenv "HOME")
                               (cut string-append <> "/.config")))
                    (cut string-append <> "/guix"))))
    (catch 'system-error
      (lambda ()
        (mkdir dir)
        dir)
      (lambda args
        (match (system-error-errno args)
          ((or EEXIST 0)
           dir)
          (err
           (leave (_ "failed to create configuration directory `~a': ~a~%")
                  dir (strerror err))))))))

(define* (fill-paragraph str width #:optional (column 0))
  "Fill STR such that each line contains at most WIDTH characters, assuming
that the first character is at COLUMN.

When STR contains a single line break surrounded by other characters, it is
converted to a space; sequences of more than one line break are preserved."
  (define (maybe-break chr result)
    (match result
      ((column newlines chars)
       (case chr
         ((#\newline)
          `(,column ,(+ 1 newlines) ,chars))
         (else
          (let ((chars  (case newlines
                          ((0) chars)
                          ((1) (cons #\space chars))
                          (else
                           (append (make-list newlines #\newline) chars))))
                (column (case newlines
                          ((0) column)
                          ((1) (+ 1 column))
                          (else 0))))
            (let ((chars  (cons chr chars))
                  (column (+ 1 column)))
              (if (> column width)
                  (let*-values (((before after)
                                 (break (cut eqv? #\space <>) chars))
                                ((len)
                                 (length before)))
                    (if (<= len width)
                        `(,len
                          0
                          ,(if (null? after)
                               before
                               (append before (cons #\newline (cdr after)))))
                        `(,column 0 ,chars)))     ; unbreakable
                  `(,column 0 ,chars)))))))))

  (match (string-fold maybe-break
                      `(,column 0 ())
                      str)
    ((_ _ chars)
     (list->string (reverse chars)))))

(define (string->recutils str)
  "Return a version of STR where newlines have been replaced by newlines
followed by \"+ \", which makes for a valid multi-line field value in the
`recutils' syntax."
  (list->string
   (string-fold-right (lambda (chr result)
                        (if (eqv? chr #\newline)
                            (cons* chr #\+ #\space result)
                            (cons chr result)))
                      '()
                      str)))

(define* (package->recutils p port
                            #:optional (width (or (and=> (getenv "WIDTH")
                                                         string->number)
                                                  80)))
  "Write to PORT a `recutils' record of package P, arranging to fit within
WIDTH columns."
  (define (description->recutils str)
    (let ((str (_ str)))
      (string->recutils
       (fill-paragraph str width
                       (string-length "description: ")))))

  ;; Note: Don't i18n field names so that people can post-process it.
  (format port "name: ~a~%" (package-name p))
  (format port "version: ~a~%" (package-version p))
  (format port "location: ~a~%"
          (or (and=> (package-location p) location->string)
              (_ "unknown")))
  (format port "home-page: ~a~%" (package-home-page p))
  (format port "license: ~a~%"
          (match (package-license p)
            (((? license? licenses) ...)
             (string-join (map license-name licenses)
                          ", "))
            ((? license? license)
             (license-name license))
            (x
             (_ "unknown"))))
  (format port "synopsis: ~a~%"
          (string-map (match-lambda
                       (#\newline #\space)
                       (chr       chr))
                      (or (and=> (package-synopsis p) _)
                          "")))
  (format port "description: ~a~%"
          (and=> (package-description p) description->recutils))
  (newline port))

(define (args-fold* options unrecognized-option-proc operand-proc . seeds)
  "A wrapper on top of `args-fold' that does proper user-facing error
reporting."
  (catch 'misc-error
    (lambda ()
      (apply args-fold options unrecognized-option-proc
             operand-proc seeds))
    (lambda (key proc msg args . rest)
      ;; XXX: MSG is not i18n'd.
      (leave (_ "invalid argument: ~a~%")
             (apply format #f msg args)))))

(define (show-guix-usage)
  (format (current-error-port)
          (_ "Try `guix --help' for more information.~%"))
  (exit 1))

(define (command-files)
  "Return the list of source files that define Guix sub-commands."
  (define directory
    (and=> (search-path %load-path "guix.scm")
           (compose (cut string-append <> "/guix/scripts")
                    dirname)))

  (define dot-scm?
    (cut string-suffix? ".scm" <>))

  ;; In Guile 2.0.5 `scandir' would return "." and ".." regardless even though
  ;; they don't match `dot-scm?'.  Work around it by doing additional
  ;; filtering.
  (if directory
      (filter dot-scm? (scandir directory dot-scm?))
      '()))

(define (commands)
  "Return the list of Guix command names."
  (map (compose (cut string-drop-right <> 4)
                basename)
       (command-files)))

(define (show-guix-help)
  (format #t (_ "Usage: guix COMMAND ARGS...
Run COMMAND with ARGS.\n"))
  (newline)
  (format #t (_ "COMMAND must be one of the sub-commands listed below:\n"))
  (newline)
  ;; TODO: Display a synopsis of each command.
  (format #t "~{   ~a~%~}" (sort (commands) string<?))
  (show-bug-report-information))

(define program-name
  ;; Name of the command-line program currently executing, or #f.
  (make-parameter #f))

(define (run-guix-command command . args)
  "Run COMMAND with the given ARGS.  Report an error when COMMAND is not
found."
  (define module
    (catch 'misc-error
      (lambda ()
        (resolve-interface `(guix scripts ,command)))
      (lambda -
        (format (current-error-port)
                (_ "guix: ~a: command not found~%") command)
        (show-guix-usage))))

  (let ((command-main (module-ref module
                                  (symbol-append 'guix- command))))
    (parameterize ((program-name command))
      (apply command-main args))))

(define guix-warning-port
  (make-parameter (current-warning-port)))

(define (guix-main arg0 . args)
  (initialize-guix)
  (let ()
    (define (option? str) (string-prefix? "-" str))
    (match args
      (()
       (format (current-error-port)
               (_ "guix: missing command name~%"))
       (show-guix-usage))
      (("--help")
       (show-guix-help))
      (("--version")
       (show-version-and-exit "guix"))
      (((? option? o) args ...)
       (format (current-error-port)
               (_ "guix: unrecognized option '~a'~%") o)
       (show-guix-usage))
      ((command args ...)
       (apply run-guix-command
              (string->symbol command)
              args)))))

;;; ui.scm ends here
