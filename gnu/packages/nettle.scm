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

(define-module (gnu packages nettle)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages m4))

(define-public nettle
  (package
    (name "nettle")
    (version "2.7.1")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/nettle/nettle-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0h2vap31yvi1a438d36lg1r1nllfx3y19r4rfxv7slrm6kafnwdw"))))
    (build-system gnu-build-system)
    (inputs `(("m4" ,m4)))
    (propagated-inputs `(("gmp" ,gmp)))
    (home-page "http://www.lysator.liu.se/~nisse/nettle/")
    (synopsis "C library for low-level crytographic functionality")
    (description
     "Nettle is a cryptographic library that is designed to fit easily
in more or less any context: In crypto toolkits for object-oriented
languages (C++, Python, Pike, ...), in applications like LSH or GNUPG,
or even in kernel space.  In most contexts, you need more than the basic
cryptographic algorithms, you also need some way to keep track of
available algorithms, their properties and variants.  You often have
some algorithm selection process, often dictated by a protocol you want
to implement.

And as the requirements of applications differ in subtle and not so
subtle ways, an API that fits one application well can be a pain to use
in a different context.  And that is why there are so many different
cryptographic libraries around.  \nNettle tries to avoid this problem by
doing one thing, the low-level crypto stuff, and providing a simple but
general interface to it.  In particular, Nettle doesn't do algorithm
selection.  It doesn't do memory allocation. It doesn't do any I/O.")
    (license gpl2+)))
