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
    '(begin
       (use-modules (guix build pull))

       (build-guix (assoc-ref %outputs "out")
                   (assoc-ref %build-inputs "tarball")
                   #:tar (assoc-ref %build-inputs "tar")
                   #:gzip (assoc-ref %build-inputs "gzip")
                   #:gcrypt (assoc-ref %build-inputs "gcrypt"))))

  (build-expression->derivation store "guix-latest" builder
                                #:inputs
                                `(("tar" ,(package-derivation store tar))
                                  ("gzip" ,(package-derivation store gzip))
                                  ("gcrypt" ,(package-derivation store
                                                                 libgcrypt))
                                  ("tarball" ,tarball))
                                #:modules '((guix build pull)
                                            (guix build utils))))


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
