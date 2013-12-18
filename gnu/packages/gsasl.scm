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

(define-module (gnu packages gsasl)
  #:use-module (gnu packages)
  #:use-module ((gnu packages compression)
                #:renamer (symbol-prefix-proc 'guix:))
  #:use-module (gnu packages gnutls)
  #:use-module (gnu packages libidn)
  #:use-module (gnu packages nettle)
  #:use-module (gnu packages shishi)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu))

(define-public libntlm
  (package
   (name "libntlm")
   (version "1.3")
   (source (origin
            (method url-fetch)
            (uri (string-append "http://www.nongnu.org/libntlm/releases/libntlm-" version
                                ".tar.gz"))
            (sha256 (base32
                     "101pr110ardcj2di940g6vaqifsaxc44h6hjn81l63dvmkj5a6ga"))))
   (build-system gnu-build-system)
   (synopsis "Libntlm, a library that implements NTLM authentication")
   (description
    "Libntlm is a library that implements NTLM authentication")
   (license lgpl2.1+)
   (home-page "http://www.nongnu.org/libntlm/")))

(define-public gss
  (package
   (name "gss")
   (version "1.0.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/gss/gss-" version
                                ".tar.gz"))
            (sha256 (base32
                     "1qa8lbkzi6ilfggx7mchfzjnchvhwi68rck3jf9j4425ncz7zsd9"))))
   (build-system gnu-build-system)
   (inputs `(("nettle" ,nettle)
             ("shishi" ,shishi)
             ("zlib" ,guix:zlib)
            ))
   (synopsis "Generic Security Service library")
   (description
    "The GNU Generic Security Service provides a free implementation of the
GSS-API specification.  It provides a generic application programming
interface for programs to access security services. Security services present
a generic, GSS interface, with which the calling application interacts via
this library, freeing the application developer from needing to know about
the underlying security implementation.")
   (license gpl3+)
   (home-page "http://www.gnu.org/software/gss/")))

(define-public gsasl
  (package
   (name "gsasl")
   (version "1.8.0")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnu/gsasl/gsasl-" version
                                ".tar.gz"))
            (sha256 (base32
                     "1rci64cxvcfr8xcjpqc4inpfq7aw4snnsbf5xz7d30nhvv8n40ii"))))
   (build-system gnu-build-system)
   (inputs `(("libidn" ,libidn)
             ("libntlm" ,libntlm)
             ("gss" ,gss)
             ("zlib" ,guix:zlib)))
   (propagated-inputs
    ;; Propagate GnuTLS because libgnutls.la reads `-lnettle', and Nettle is a
    ;; propagated input of GnuTLS.
    `(("gnutls" ,gnutls)))
   (synopsis "Simple Authentication and Security Layer library")
   (description
    "GNU SASL is an implementation of the Simple Authentication and
Security Layer framework.  On network servers such as IMAP or SMTP servers,
SASL is used to handle client/server authentication.  This package contains
both a library and a command-line tool to access the library.")
   (license gpl3+)
   (home-page "http://www.gnu.org/software/gsasl/")))
