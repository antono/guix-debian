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

(define-module (guix scripts pull)
  #:use-module (guix ui)
  #:use-module (guix store)
  #:use-module (guix config)
  #:use-module (guix packages)
  #:use-module (guix derivations)
  #:use-module (guix download)
  #:use-module (gnu packages base)
  #:use-module ((gnu packages bootstrap)
                #:select (%bootstrap-guile))
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnupg)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-37)
  #:export (guix-pull))

(define %snapshot-url
  ;; "http://hydra.gnu.org/job/guix/master/tarball/latest/download"
  "http://git.savannah.gnu.org/cgit/guix.git/snapshot/guix-master.tar.gz"
  )

(define (unpack store tarball)
  "Return a derivation that unpacks TARBALL into STORE and compiles Scheme
files."
  (define builder
    `(begin
       (use-modules (guix build utils)
                    (system base compile)
                    (ice-9 ftw)
                    (ice-9 match)
                    (srfi srfi-1)
                    (srfi srfi-11)
                    (srfi srfi-26))

       (setvbuf (current-output-port) _IOLBF)
       (setvbuf (current-error-port) _IOLBF)

       (let ((out     (assoc-ref %outputs "out"))
             (tar     (assoc-ref %build-inputs "tar"))
             (gzip    (assoc-ref %build-inputs "gzip"))
             (gcrypt  (assoc-ref %build-inputs "gcrypt"))
             (tarball (assoc-ref %build-inputs "tarball")))

         (define* (compile-file* file #:key output-file (opts '()))
           ;; Like 'compile-file', but remove any (guix …) and (gnu …) modules
           ;; created during the process as an ugly workaround for
           ;; <http://bugs.gnu.org/15602> (FIXME).  This ensures correctness,
           ;; but is overly conservative and very slow.

           (define (module-directory+file module)
             ;; Return the directory for MODULE, like the 'dir-hint' in
             ;; boot-9.scm.
             (match (module-name module)
               ((beginning ... last)
                (values (string-concatenate
                         (map (lambda (elt)
                                (string-append (symbol->string elt)
                                               file-name-separator-string))
                              beginning))
                        (symbol->string last)))))

           (define (clear-module-tree! root)
             ;; Delete all the modules under ROOT.
             (hash-for-each (lambda (name module)
                              (module-remove! root name)
                              (let-values (((dir name)
                                            (module-directory+file module)))
                                (set-autoloaded! dir name #f))
                              (clear-module-tree! module))
                            (module-submodules root))
             (hash-clear! (module-submodules root)))

           (compile-file file #:output-file output-file #:opts opts)

           (for-each (compose clear-module-tree! resolve-module)
                     '((guix) (gnu))))

         (setenv "PATH" (string-append tar "/bin:" gzip "/bin"))

         (system* "tar" "xvf" tarball)
         (match (scandir "." (lambda (name)
                               (and (not (member name '("." "..")))
                                    (file-is-directory? name))))
           ((dir)
            (chdir dir))
           (x
            (error "tarball did not produce a single source directory" x)))

         (format #t "copying and compiling Guix to `~a'...~%" out)

         ;; Copy everything under guix/ and gnu/ plus guix.scm.
         (copy-recursively "guix" (string-append out "/guix"))
         (copy-recursively "gnu" (string-append out "/gnu"))
         (copy-file "guix.scm" (string-append out "/guix.scm"))

         ;; Add a fake (guix config) module to allow the other modules to be
         ;; compiled.  The user's (guix config) is the one that will be used.
         (copy-file "guix/config.scm.in"
                    (string-append out "/guix/config.scm"))
         (substitute* (string-append out "/guix/config.scm")
           (("@LIBGCRYPT@")
            (string-append gcrypt "/lib/libgcrypt")))

         ;; Augment the search path so Scheme code can be compiled.
         (set! %load-path (cons out %load-path))
         (set! %load-compiled-path (cons out %load-compiled-path))

         ;; Compile the .scm files.
         (for-each (lambda (file)
                     (when (string-suffix? ".scm" file)
                       (let ((go (string-append (string-drop-right file 4)
                                                ".go")))
                         (format (current-error-port)
                                 "compiling '~a'...~%" file)
                         (compile-file* file
                                        #:output-file go
                                        #:opts
                                        %auto-compilation-options))))

                   (find-files out "\\.scm"))

         ;; Remove the "fake" (guix config).
         (delete-file (string-append out "/guix/config.scm"))
         (delete-file (string-append out "/guix/config.go")))))

  (build-expression->derivation store "guix-latest" builder
                                #:inputs
                                `(("tar" ,(package-derivation store tar))
                                  ("gzip" ,(package-derivation store gzip))
                                  ("gcrypt" ,(package-derivation store
                                                                 libgcrypt))
                                  ("tarball" ,tarball))
                                #:modules '((guix build utils))))


;;;
;;; Command-line options.
;;;

(define %default-options
  ;; Alist of default option values.
  `((tarball-url . ,%snapshot-url)))

(define (show-help)
  (display (_ "Usage: guix pull [OPTION]...
Download and deploy the latest version of Guix.\n"))
  (display (_ "
      --verbose          produce verbose output"))
  (display (_ "
      --url=URL          download the Guix tarball from URL"))
  (display (_ "
      --bootstrap        use the bootstrap Guile to build the new Guix"))
  (newline)
  (display (_ "
  -h, --help             display this help and exit"))
  (display (_ "
  -V, --version          display version information and exit"))
  (newline)
  (show-bug-report-information))

(define %options
  ;; Specifications of the command-line options.
  (list (option '("verbose") #f #f
                (lambda (opt name arg result)
                  (alist-cons 'verbose? #t result)))
        (option '("url") #t #f
                (lambda (opt name arg result)
                  (alist-cons 'tarball-url arg
                              (alist-delete 'tarball-url result))))
        (option '("bootstrap") #f #f
                (lambda (opt name arg result)
                  (alist-cons 'bootstrap? #t result)))

        (option '(#\h "help") #f #f
                (lambda args
                  (show-help)
                  (exit 0)))
        (option '(#\V "version") #f #f
                (lambda args
                  (show-version-and-exit "guix pull")))))

(define (guix-pull . args)
  (define (parse-options)
    ;; Return the alist of option values.
    (args-fold* args %options
                (lambda (opt name arg result)
                  (leave (_ "~A: unrecognized option~%") name))
                (lambda (arg result)
                  (leave (_ "~A: unexpected argument~%") arg))
                %default-options))

  (with-error-handling
    (let* ((opts  (parse-options))
           (store (open-connection))
           (url   (assoc-ref opts 'tarball-url)))
      (let ((tarball (download-to-store store url "guix-latest.tar.gz")))
        (unless tarball
          (leave (_ "failed to download up-to-date source, exiting\n")))
        (parameterize ((%guile-for-build
                        (package-derivation store
                                            (if (assoc-ref opts 'bootstrap?)
                                                %bootstrap-guile
                                                guile-final)))
                       (current-build-output-port
                        (if (assoc-ref opts 'verbose?)
                            (current-error-port)
                            (%make-void-port "w"))))
          (let* ((config-dir (config-directory))
                 (source     (unpack store tarball))
                 (source-dir (derivation->output-path source)))
            (if (show-what-to-build store (list source))
                (if (build-derivations store (list source))
                    (let ((latest (string-append config-dir "/latest")))
                      (add-indirect-root store latest)
                      (switch-symlinks latest source-dir)
                      (format #t
                              (_ "updated ~a successfully deployed under `~a'~%")
                              %guix-package-name latest)
                      #t)
                    (leave (_ "failed to update Guix, check the build log~%")))
                (begin
                  (display (_ "Guix already up to date\n"))
                  #t))))))))
