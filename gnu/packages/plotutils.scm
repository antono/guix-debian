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

(define-module (gnu packages plotutils)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages libpng)
  #:use-module (gnu packages))

(define-public plotutils
  (package
    (name "plotutils")
    (version "2.6")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnu/plotutils/plotutils-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1arkyizn5wbgvbh53aziv3s6lmd3wm9lqzkhxb3hijlp1y124hjg"))))
    (build-system gnu-build-system)
    (arguments '(#:patches (list (assoc-ref %build-inputs "patch/jmpbuf"))))
    (inputs `(("libpng" ,libpng)
              ("libx11" ,libx11)
              ("libxt" ,libxt)
              ("libxaw" ,libxaw)
              ("patch/jmpbuf"
               ,(search-patch "plotutils-libpng-jmpbuf.patch"))))
    (home-page
     "http://www.gnu.org/software/plotutils/")
    (synopsis "Plotting utilities and library")
    (description
     "The GNU plotutils package contains software for both programmers and
technical users.  Its centerpiece is libplot, a powerful C/C++ function
library for exporting 2-D vector graphics in many file formats, both vector
and raster.  It can also do vector graphics animations.

libplot is device-independent in the sense that its API (application
programming interface) does not depend on the type of graphics file to be
exported.

Besides libplot, the package contains command-line programs for plotting
scientific data.  Many of them use libplot to export graphics.")
    (license gpl2+)))
