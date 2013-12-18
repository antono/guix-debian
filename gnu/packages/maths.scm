;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
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

(define-module (gnu packages maths)
  #:use-module (gnu packages)
  #:use-module ((guix licenses)
                #:renamer (symbol-prefix-proc 'license:))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages xml))

(define-public units
  (package
   (name "units")
   (version "2.02")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/units/units-" version
                                ".tar.gz"))
            (sha256 (base32
                     "16jfji9g1zc99agd5dcinajinhcxr4dgq2lrbc9md69ir5qgld1b"))))
   (build-system gnu-build-system)
   (synopsis "Conversion between thousands of scales")
   (description
    "GNU Units converts between measured quantities between units of
measure.  It can handle scale changes through adaptive usage of standard
scale prefixes (micro-, kilo-, etc.).  It can also handle nonlinear
conversions such as Fahrenheit to Celsius.  Its interpreter is powerful
enough to be used effectively as a scientific calculator.")
   (license license:gpl3+)
   (home-page "http://www.gnu.org/software/units/")))

(define-public gsl
  (package
    (name "gsl")
    (version "1.16")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/gsl/gsl-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0lrgipi0z6559jqh82yx8n4xgnxkhzj46v96dl77hahdp58jzg3k"))))
    (build-system gnu-build-system)
    (arguments
     `(#:parallel-tests? #f
       #:phases
        (alist-replace
         'configure
         (lambda* (#:key target system outputs #:allow-other-keys #:rest args)
           (let ((configure (assoc-ref %standard-phases 'configure)))
             ;; disable numerically unstable test on i686, see thread at
             ;; http://lists.gnu.org/archive/html/bug-gsl/2011-11/msg00019.html
             (if (string=? (or target system) "i686-linux")
                 (substitute* "ode-initval2/Makefile.in"
                   (("TESTS = \\$\\(check_PROGRAMS\\)") "TESTS =")))
             (apply configure args)))
         %standard-phases)))
    (home-page "http://www.gnu.org/software/gsl/")
    (synopsis "Numerical library for C and C++")
    (description
     "The GNU Scientific Library is a library for numerical analysis in C
and C++.  It includes a wide range of mathematical routines, with over 1000
functions in total.  Subject areas covered by the library include:
differential equations, linear algebra, Fast Fourier Transforms and random
numbers.")
    (license license:gpl3+)))

(define-public glpk
  (package
    (name "glpk")
    (version "4.52.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/glpk/glpk-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0nz9ngmx23c8gbjr8l8ygnfaanxj2mwbl8awpg630bgrkxdnhc9j"))))
    (build-system gnu-build-system)
    (inputs
     `(("gmp" ,gmp)))
    (arguments
     `(#:configure-flags '("--with-gmp")))
    (home-page "http://www.gnu.org/software/glpk/")
    (synopsis "GNU Linear Programming Kit, supporting the MathProg language")
    (description
     "GLPK is a C library for solving large-scale linear programming (LP),
mixed integer programming (MIP), and other related problems.  It supports the
GNU MathProg modeling language, a subset of the AMPL language, and features a
translator for the language.  In addition to the C library, a stand-alone
LP/MIP solver is included in the package.")
    (license license:gpl3+)))

(define-public pspp
  (package
    (name "pspp")
    (version "0.8.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/pspp/pspp-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0qhxsdbwxd3cn1shc13wxvx2lg32lp4z6sz24kv3jz7p5xfi8j7x"))
      (patches (list (search-patch "pspp-tests.patch")))))
    (build-system gnu-build-system)
    (inputs
     `(("cairo" ,cairo)
       ("fontconfig" ,fontconfig)
       ("gettext" ,gnu-gettext)
       ("gsl" ,gsl)
       ("libxml2" ,libxml2)
       ("pango" ,pango)
       ("readline" ,readline)
       ("gtk" ,gtk+-2)
       ("gtksourceview" ,gtksourceview)
       ("zlib" ,zlib)))
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))
    (home-page "http://www.gnu.org/software/pspp/")
    (synopsis "Statistical analysis")
    (description
     "GNU PSPP is a statistical analysis program.  It can perform
descriptive statistics, T-tests, linear regression and non-parametric tests. 
It features both a graphical interface as well as command-line input. PSPP is
designed to interoperate with Gnumeric, LibreOffice and OpenOffice.  Data can
be imported from spreadsheets, text files and database sources and it can be
output in text, PostScript, PDF or HTML.")
    (license license:gpl3+)))

(define-public lapack
  (package
    (name "lapack")
    (version "3.4.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "http://www.netlib.org/lapack/lapack-"
                          version ".tgz"))
      (sha256
       (base32
        "1w7sf8888m7fi2kyx1fzgbm22193l8c2d53m8q1ibhvfy6m5v9k0"))
      (snippet
       ;; Remove non-free files.
       ;; See <http://icl.cs.utk.edu/lapack-forum/archives/lapack/msg01383.html>.
       '(for-each (lambda (file)
                    (format #t "removing '~a'~%" file)
                    (delete-file file))
                  '("lapacke/example/example_DGESV_rowmajor.c"
                    "lapacke/example/example_ZGESV_rowmajor.c"
                    "DOCS/psfig.tex")))))
    (build-system cmake-build-system)
    (home-page "http://www.netlib.org/lapack/")
    (inputs `(("fortran" ,gfortran-4.8)
              ("python" ,python-2)))
    (arguments
     `(#:modules ((guix build cmake-build-system)
                  (guix build utils)
                  (srfi srfi-1))
       #:phases (alist-cons-before
                 'check 'patch-python
                 (lambda* (#:key inputs #:allow-other-keys)
                   (let ((python (assoc-ref inputs "python")))
                     (substitute* "lapack_testing.py"
                       (("/usr/bin/env python") python))))
                 %standard-phases)))
    (synopsis "Library for numerical linear algebra")
    (description
     "LAPACK is a Fortran 90 library for solving the most commonly occurring
problems in numerical linear algebra.")
    (license (license:bsd-style "file://LICENSE"
                                "See LICENSE in the distribution."))))
