;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages multiprecision)
  #:use-module (guix licenses)
  #:use-module (gnu packages)
  #:use-module (gnu packages m4)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public gmp
  (package
   (name "gmp")
   (version "5.1.1")
   (source (origin
            (method url-fetch)
            (uri
             (string-append "mirror://gnu/gmp/gmp-"
                            version ".tar.xz"))
            (sha256
             (base32
              "1hili06lcf0clg5qfvz7knm6pmj6ab54yhsvskp1mdny5xw4vmjb"))))
   (build-system gnu-build-system)
   (native-inputs `(("m4" ,m4)))
   (arguments `(#:configure-flags
                '(;; Build a "fat binary", with routines for several
                  ;; sub-architectures.
                  "--enable-fat"
                  "--enable-cxx")))
   (synopsis "Multiple-precision arithmetic library")
   (description
    "GMP is a free library for arbitrary precision arithmetic, operating on
signed integers, rational numbers, and floating point numbers.  There is no
practical limit to the precision except the ones implied by the available
memory in the machine GMP runs on.  GMP has a rich set of functions, and the
functions have a regular interface.

The main target applications for GMP are cryptography applications and
research, Internet security applications, algebra systems, computational
algebra research, etc.

GMP is carefully designed to be as fast as possible, both for small operands
and for huge operands.  The speed is achieved by using fullwords as the basic
arithmetic type, by using fast algorithms, with highly optimised assembly
code for the most common inner loops for a lot of CPUs, and by a general
emphasis on speed.

GMP is faster than any other bignum library.  The advantage for GMP increases
with the operand sizes for many operations, since GMP uses asymptotically
faster algorithms.")
   (license lgpl3+)
   (home-page "http://gmplib.org/")))

(define-public mpfr
  (package
   (name "mpfr")
   (version "3.1.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/mpfr/mpfr-" version
                                ".tar.xz"))
            (sha256 (base32
                     "0fs501qi8l523gs3cpy4jjcnvwxggyfbklcys80wq236xx3hz79r"))))
   (build-system gnu-build-system)
   (propagated-inputs `(("gmp" ,gmp)))            ; <mpfr.h> refers to <gmp.h>
   (synopsis "C library for arbitrary precision floating-point arithmetic")
   (description
    "The GNU MPFR library is a C library for multiple-precision
floating-point computations with correct rounding.  MPFR is based on the GMP
multiple-precision library.

The main goal of MPFR is to provide a library for multiple-precision
floating-point computation which is both efficient and has a well-defined
semantics.  It copies the good ideas from the ANSI/IEEE-754 standard for
double-precision floating-point arithmetic (53-bit mantissa).")
   (license lgpl3+)
   (home-page "http://www.mpfr.org/")))

(define-public mpc
  (package
   (name "mpc")
   (version "1.0.1")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "mirror://gnu/mpc/mpc-" version ".tar.gz"))
            (sha256 (base32
                     "1zq0fidp1jii2j5k5n9hmx55a6wwid33gjzhimvxq9d5zrf82npd"))))
   (build-system gnu-build-system)
   (propagated-inputs `(("gmp" ,gmp)              ; <mpc.h> refers to both
                        ("mpfr" ,mpfr)))
   (synopsis "C library for arbitrary precision complex arithmetic")
   (description
    "GNU MPC is a C library for the arithmetic of complex numbers with
arbitrarily high precision and correct rounding of the result. It extends
the principles of the IEEE-754 standard for fixed precision real floating
point numbers to complex numbers, providing well-defined semantics for
every operation. At the same time, speed of operation at high precision
is a major design goal. The library is built upon and follows the same
principles as GNU MPFR.")
   (license lgpl3+)
   (home-page "http://mpc.multiprecision.org/")))
