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

(define-module (gnu packages gperf)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public gperf
  (package
    (name "gperf")
    (version "3.0.4")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/gperf/gperf-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0gnnm8iqcl52m8iha3sxrzrl9mcyhg7lfrhhqgdn4zj00ji14wbn"))))
    (build-system gnu-build-system)
    (arguments '(#:parallel-tests? #f))
    (home-page "http://www.gnu.org/software/gperf/")
    (synopsis "Perfect hash function generator")
    (description
     "GNU gperf is a perfect hash function generator.  For a given
list of strings, it produces a hash function and hash table, in
form of C or C++ code, for looking up a value depending on the
input string.  The hash function is perfect, which means that
the hash table has no collisions, and the hash table lookup
needs a single string comparison only.

GNU gperf is highly customizable.  There are options for
generating C or C++ code, for emitting switch statements or
nested ifs instead of a hash table, and for tuning the algorithm
employed by gperf.")
    (license gpl3+)))
