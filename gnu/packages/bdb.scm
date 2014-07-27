;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012 Andreas Enge <andreas@enge.fr>
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

(define-module (gnu packages bdb)
  #:use-module (gnu packages)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public bdb
  (package
   (name "bdb")
   (version "5.3.21")
   (source (origin
            (method url-fetch)
            (uri (string-append "http://download.oracle.com/berkeley-db/db-" version
                                ".tar.gz"))
            (sha256 (base32
                     "1f2g2612lf8djbwbwhxsvmffmf9d7693kh2l20195pqp0f9jmnfx"))))
   (build-system gnu-build-system)
   (outputs '("out"                             ; programs, libraries, headers
              "doc"))                           ; 94 MiB of HTML docs
   (arguments
    '(#:tests? #f                            ; no check target available
      #:phases
      (alist-replace
       'configure
       (lambda* (#:key outputs #:allow-other-keys)
         (let ((out (assoc-ref outputs "out"))
               (doc (assoc-ref outputs "doc")))
           ;; '--docdir' is not honored, so we need to patch.
           (substitute* "dist/Makefile.in"
             (("docdir[[:blank:]]*=.*")
              (string-append "docdir = " doc "/share/doc/bdb")))

           (zero?
            (system* "./dist/configure"
                     (string-append "--prefix=" out)
                     (string-append "CONFIG_SHELL=" (which "bash"))
                     (string-append "SHELL=" (which "bash"))

                     ;; The compatibility mode is needed by some packages,
                     ;; notably iproute2.
                     "--enable-compat185"))))
       %standard-phases)))
   (synopsis "db, the Berkeley database")
   (description
    "Berkeley DB is an embeddable database allowing developers the choice of
SQL, Key/Value, XML/XQuery or Java Object storage for their data model.")
   (license (bsd-style "file://LICENSE"
                       "See LICENSE in the distribution."))
   (home-page "http://www.oracle.com/us/products/database/berkeley-db/overview/index.html")))
