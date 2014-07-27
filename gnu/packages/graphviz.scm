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

(define-module (gnu packages graphviz)
  #:use-module (guix packages)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages image)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gd)
  #:use-module ((guix licenses) #:select (lgpl2.0+ epl1.0)))

(define-public graphviz
  (package
    (name "graphviz")
    (version "2.28.0")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://www.graphviz.org/pub/graphviz/ARCHIVE/graphviz-"
                   version
                   ".tar.gz"))
             (sha256
              (base32
               "0xpwg99cd8sp0c6r8klsmc66h1pday64kmnr4v6f9jkqqmrpkank"))))
    (build-system gnu-build-system)
    (arguments
     ;; FIXME: rtest/rtest.sh is a ksh script (!).  Add ksh as an input.
     '(#:tests? #f

       #:phases (alist-cons-before
                 'build 'pre-build
                 (lambda _
                   ;; Work around bogus makefile when using an external
                   ;; libltdl.  Failing to do so, one hits this error:
                   ;; "No rule to make target `-lltdl', needed by `libgvc.la'."
                   (substitute* "lib/gvc/Makefile"
                     (("am__append_5 *=.*")
                      "am_append_5 =\n")))
                 %standard-phases)))
    (inputs
     `(("libXrender" ,libxrender)
       ("libX11" ,libx11)
       ("gts" ,gts)
       ("gd" ,gd)                                 ; FIXME: Our GD is too old
       ("pango" ,pango)
       ("fontconfig" ,fontconfig)
       ("freetype" ,freetype)
       ("libltdl" ,libtool)
       ("libXaw" ,libxaw)
       ("expat" ,expat)
       ("libjpeg" ,libjpeg)
       ("libpng" ,libpng)))
    (native-inputs
     `(("bison" ,bison)
       ("pkg-config" ,pkg-config)))
    (home-page "http://www.graphviz.org/")
    (synopsis "Graph visualization software")
    (description
     "Graphviz is a graph visualization tool suite.  Graph visualization is a
way of representing structural information as diagrams of abstract graphs and
networks.  It has important applications in networking, bioinformatics,
software engineering, database and web design, machine learning, and in visual
interfaces for other technical domains.")
    (license epl1.0)))

(define-public gts
  (package
    (name "gts")
    (version "0.7.6")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/gts/gts-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "07mqx09jxh8cv9753y2d2jsv7wp8vjmrd7zcfpbrddz3wc9kx705"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-before
                 'check 'pre-check
                 (lambda _
                   (chmod "test/boolean/test.sh" #o777))
                 %standard-phases)

       ;; Some data files used by the test suite are missing.
       ;; See <http://sourceforge.net/p/gts/bugs/41/>.
       #:tests? #f))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     ;; The gts.pc file has glib-2.0 as required.
     `(("glib" ,glib)))
    (home-page "http://gts.sourceforge.net/")

    ;; Note: Despite the name, this is not official GNU software.
    (synopsis "Triangulated Surface Library")
    (description
     "Library intended to provide a set of useful functions to deal with
3D surfaces meshed with interconnected triangles.")
    (license lgpl2.0+)))
