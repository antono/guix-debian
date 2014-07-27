;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014 Ludovic Courtès <ludo@gnu.org>
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

(define-module (gnu packages skribilo)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix licenses)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages lout)
  #:use-module (gnu packages imagemagick)
  #:use-module (gnu packages ghostscript))

(define-public skribilo
  (package
    (name "skribilo")
    (version "0.9.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://savannah/skribilo/skribilo-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0wwi996403wzcp8s8iyc2p6w7f9v39lwmy35ysdd3wc31i5dy19q"))))
    (build-system gnu-build-system)
    (arguments
     ;; Make the modules available under the usual location.
     '(#:configure-flags (list (string-append "--with-guilemoduledir="
                                              (assoc-ref %outputs "out")
                                              "/share/guile/site/2.0"))
       #:parallel-build? #f))
    ;; TODO: Add Ploticus.
    (inputs `(("guile" ,guile-2.0)
              ("imagemagick" ,imagemagick)
              ("ghostscript" ,ghostscript)        ; for 'convert'
              ("lout" ,lout)))

    ;; The 'skribilo' command needs them, and for people using Skribilo as a
    ;; library, these inputs are needed as well.
    (propagated-inputs `(("guile-reader" ,guile-reader/guile-2.0)
                         ("guile-lib" ,guile-lib)))

    (home-page "http://www.nongnu.org/skribilo/")
    (synopsis "Document production tool written in Guile Scheme")
    (description
     "Skribilo is a free document production tool that takes a structured
document representation as its input and renders that document in a variety of
output formats: HTML and Info for on-line browsing, and Lout and LaTeX for
high-quality hard copies.

The input document can use Skribilo's markup language to provide information
about the document's structure, which is similar to HTML or LaTeX and does not
require expertise. Alternatively, it can use a simpler, “markup-less” format
that borrows from Emacs' outline mode and from other conventions used in
emails, Usenet and text.

Lastly, Skribilo provides Guile Scheme APIs.")
    (license gpl3+)))
