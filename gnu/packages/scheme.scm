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

(define-module (gnu packages scheme)
  #:use-module (gnu packages)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages patchelf)
  #:use-module (gnu packages which)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages avahi)
  #:use-module (gnu packages libphidget)
  #:use-module (ice-9 match))

(define-public mit-scheme
  (package
    (name "mit-scheme")
    (version "9.1.1")
    (source #f)                                   ; see below
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f                                ; no "check" target
       #:phases
       (alist-replace
        'unpack
        (lambda* (#:key inputs #:allow-other-keys)
          (and (zero? (system* "tar" "xzvf"
                               (assoc-ref inputs "source")))
               (chdir ,(string-append name "-" version))
               (begin
                 ;; Delete these dangling symlinks since they break
                 ;; `patch-shebangs'.
                 (for-each delete-file
                           (append (find-files "src/lib/lib" "\\.so$")
                                   (find-files "src/lib" "^ffi-test")))
                 (chdir "src")
                 #t)))
        (alist-replace
         'build
         (lambda* (#:key system outputs #:allow-other-keys)
           (let ((out (assoc-ref outputs "out")))
             (if (or (string-prefix? "x86_64" system)
                     (string-prefix? "i686" system))
                 (zero? (system* "make" "compile-microcode"))
                 (zero? (system* "./etc/make-liarc.sh"
                                 (string-append "--prefix=" out))))))
         %standard-phases))))
    (inputs
     `(;; TODO: Build doc when TeX Live is available.
       ;; ("automake" ,automake)
       ;; ("texlive-core" ,texlive-core)
       ("texinfo" ,texinfo)
       ("m4" ,m4)

       ("source"

        ;; MIT/GNU Scheme is not bootstrappable, so it's recommended to
        ;; compile from the architecture-specific tarballs, which contain
        ;; pre-built binaries.  It leads to more efficient code than when
        ;; building the tarball that contains generated C code instead of
        ;; those binaries.
        ,(origin
          (method url-fetch)
          (uri (string-append "mirror://gnu/mit-scheme/stable.pkg/"
                              version "/mit-scheme-"
                              version "-"
                              (match (%current-system)
                                ("x86_64-linux" "x86-64")
                                ("i686-linux" "i386")
                                (_ "c"))
                              ".tar.gz"))
          (sha256
           (match (%current-system)
             ("x86_64-linux"
              (base32
               "1wcxm9hyfc53myvlcn93fyqrnnn4scwkknl9hkbp1cphc6mp291x"))
             ("i686-linux"
              (base32
               "0vi760fy550d9db538m0vzbq1mpdncvw9g8bk4lswk0kcdira55z"))
             (_
              (base32
               "0pclakzwxbqgy6wqwvs6ml62wgby8ba8xzmwzdwhx1v8wv05yw1j"))))))))
    (home-page "http://www.gnu.org/software/mit-scheme/")
    (synopsis "Scheme implementation with integrated editor and debugger")
    (description
     "MIT/GNU Scheme is an implementation of the Scheme programming
language, providing an interpreter, compiler, source-code debugger,
integrated Emacs-like editor, and a large runtime library.  MIT/GNU
Scheme is best suited to programming large applications with a rapid
development cycle.")
    (license gpl2+)))

(define-public bigloo
  (package
    (name "bigloo")
    (version "4.0a")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://ftp-sop.inria.fr/indes/fp/Bigloo/bigloo"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1771z43nmf9awjvlvrpjfhzcfxsbw2qipir8g9r47sygf2vn59yl"))))
    (build-system gnu-build-system)
    (arguments
     '(#:patches (list (assoc-ref %build-inputs "patch/shebangs"))
       #:test-target "test"
       #:phases (alist-replace
                 'configure
                 (lambda* (#:key outputs #:allow-other-keys)

                   (substitute* "configure"
                     (("^shell=.*$")
                      (string-append "shell=" (which "bash") "\n")))

                   ;; Those variables are used by libgc's `configure'.
                   (setenv "SHELL" (which "bash"))
                   (setenv "CONFIG_SHELL" (which "bash"))

                   ;; The `configure' script doesn't understand options
                   ;; of those of Autoconf.
                   (let ((out (assoc-ref outputs "out")))
                     (zero?
                      (system* "./configure"
                               (string-append "--prefix=" out)
                               (string-append"--mv=" (which "mv"))
                               (string-append "--rm=" (which "rm"))))))
                 (alist-cons-after
                  'patch 'patch-absolute-file-names
                  (lambda _
                    (substitute* (cons "configure"
                                       (find-files "gc" "^install-gc"))
                      (("/bin/rm") (which "rm"))
                      (("/bin/mv") (which "mv"))))
                  (alist-cons-after
                   'install 'install-emacs-modes
                   (lambda* (#:key outputs #:allow-other-keys)
                     (let* ((out (assoc-ref outputs "out"))
                            (dir (string-append out "/share/emacs/site-lisp")))
                       (zero? (system* "make" "-C" "bmacs" "all" "install"
                                       (string-append "EMACSBRAND=emacs24")
                                       (string-append "EMACSDIR=" dir)))))
                   %standard-phases)))))
    (inputs
     `(("emacs" ,emacs)
       ("patch/shebangs" ,(search-patch "bigloo-gc-shebangs.patch"))

       ;; Optional APIs for which Bigloo has bindings.
       ("avahi" ,avahi)
       ("libphidget" ,libphidget)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("gmp" ,gmp)))                             ; bigloo.h refers to gmp.h
    (home-page "http://www-sop.inria.fr/indes/fp/Bigloo/")
    (synopsis "Bigloo, an efficient Scheme compiler")
    (description
     "Bigloo is a Scheme implementation devoted to one goal: enabling
Scheme based programming style where C(++) is usually
required.  Bigloo attempts to make Scheme practical by offering
features usually presented by traditional programming languages
but not offered by Scheme and functional programming.  Bigloo
compiles Scheme modules.  It delivers small and fast stand alone
binary executables.  Bigloo enables full connections between
Scheme and C programs, between Scheme and Java programs, and
between Scheme and C# programs.")
    (license gpl2+)))

(define-public hop
  (package
    (name "hop")
    (version "2.4.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://ftp-sop.inria.fr/indes/fp/Hop/hop-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1v2r4ga58kk1sx0frn8qa8ccmjpic9csqzpk499wc95y9c4b1wy3"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (alist-replace
        'configure
        (lambda* (#:key inputs outputs #:allow-other-keys)
          (let ((out (assoc-ref outputs "out")))
            (zero?
             (system* "./configure"
                      (string-append"--prefix=" out)))))
        (alist-cons-after
         'strip 'patch-rpath
         (lambda* (#:key outputs #:allow-other-keys)
           ;; Patch the RPATH of every installed library to point to $out/lib
           ;; instead of $TMPDIR.  Note that "patchelf --set-rpath" produces
           ;; invalid binaries when used before stripping.
           (let ((out    (assoc-ref outputs "out"))
                 (tmpdir (getcwd)))
             (every (lambda (lib)
                      (let* ((in    (open-pipe* OPEN_READ "patchelf"
                                                "--print-rpath" lib))
                             (rpath (read-line in)))
                        (and (zero? (close-pipe in))
                             (let ((rpath* (regexp-substitute/global
                                            #f (regexp-quote tmpdir) rpath
                                            'pre out 'post)))
                               (or (equal? rpath rpath*)
                                   (begin
                                     (format #t "~a: changing RPATH from `~a' to `~a'~%"
                                             lib rpath rpath*)
                                     (zero?
                                      (system* "patchelf" "--set-rpath"
                                               rpath* lib))))))))
                    (append (find-files (string-append out "/bin")
                                        ".*")
                            (find-files (string-append out "/lib")
                                        "\\.so$")))))
         %standard-phases))
       #:tests? #f                                ; no test suite
       #:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 popen)
                  (ice-9 regex)
                  (ice-9 rdelim)
                  (srfi srfi-1))))
    (inputs `(("bigloo" ,bigloo)
              ("which" ,which)
              ("patchelf" ,patchelf)))
    (home-page "http://hop.inria.fr/")
    (synopsis "A multi-tier programming language for the Web 2.0")
    (description
     "HOP is a multi-tier programming language for the Web 2.0 and the
so-called diffuse Web.  It is designed for programming interactive web
applications in many fields such as multimedia (web galleries, music players,
...), ubiquitous and house automation (SmartPhones, personal appliance),
mashups, office (web agendas, mail clients, ...), etc.")
    (license gpl2+)))

(define-public chicken
  (package
    (name "chicken")
    (version "4.8.0.3")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://code.call-cc.org/releases/4.8.0/chicken-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1hwrnc2dhgbnz3mlpcb4qvg76kwsfzqylw24gxyy91jmygk1853a"))))
    (build-system gnu-build-system)
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1))

       ;; No `configure' script; run "make check" after "make install" as
       ;; prescribed by README.
       #:phases (alist-cons-after
                 'install 'check
                 (assoc-ref %standard-phases 'check)
                 (fold alist-delete %standard-phases
                       '(configure check)))

       #:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list "PLATFORM=linux"
                            (string-append "PREFIX=" out)
                            (string-append "VARDIR=" out "/var/lib")))

       ;; Parallel builds are not supported, as noted in README.
       #:parallel-build? #f))
    (home-page "http://www.call-cc.org/")
    (synopsis "R5RS Scheme implementation that compiles native code via C")
    (description
     "CHICKEN is a compiler for the Scheme programming language.  CHICKEN
produces portable and efficient C, supports almost all of the R5RS Scheme
language standard, and includes many enhancements and extensions.")
    (license bsd-3)))

(define-public scheme48
  (package
    (name "scheme48")
    (version "1.9")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://s48.org/" version
                                 "/scheme48-" version ".tgz"))
             (sha256
              (base32
               "0rw2lz5xgld0klvld292ds6hvfk5l12vskzgf1hhwjdpa38r3fnw"))))
    (build-system gnu-build-system)
    (arguments `(#:patches (list (assoc-ref %build-inputs "patch/tests"))))
    (inputs `(("patch/tests" ,(search-patch "scheme48-tests.patch"))))
    (home-page "http://s48.org/")
    (synopsis "Scheme implementation using a bytecode interpreter")
    (description
     "Scheme 48 is an implementation of Scheme based on a byte-code
interpreter and is designed to be used as a testbed for experiments in
implementation techniques and as an expository tool.")

    ;; Most files are BSD-3; see COPYING for the few exceptions.
    (license bsd-3)))
