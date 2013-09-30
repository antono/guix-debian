;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
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

(define-module (gnu packages texlive)
  #:use-module ((guix licenses)
                #:renamer (symbol-prefix-proc 'license:))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages gd)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages libpng)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages which)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tcsh)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages zip)
  #:autoload   (gnu packages texinfo) (texinfo))

(define texlive-extra-src
  (origin
    (method url-fetch)
    (uri "ftp://tug.org/historic/systems/texlive/2013/texlive-20130530-extra.tar.xz")
    (sha256 (base32
              "15r1qyn7x1iamiiycylx8vzsg27h1r962v6dz9q70f9pdp2rjr6s"))))

(define texlive-texmf-src
  (origin
    (method url-fetch)
    (uri "ftp://tug.org/historic/systems/texlive/2013/texlive-20130530-texmf.tar.xz")
    (sha256 (base32
              "09kza0ha0x9cm4k2qm9w31h3g94y9hy17jahnnsirqyy8rpdqgwg"))))

(define-public texlive
  (package
   (name "texlive")
   (version "2013")
   (source (origin
            (method url-fetch)
            (uri "ftp://tug.org/historic/systems/texlive/2013/texlive-20130530-source.tar.xz")
            (sha256 (base32
                     "1m3ripkmra53jwkaqcxxhabc3yvqrfm7pfxldnqirp849hp861d9"))))
   (build-system gnu-build-system)
   (inputs `(("texlive-extra-src" ,texlive-extra-src)
             ("texlive-texmf-src" ,texlive-texmf-src)
             ("cairo" ,cairo)
             ("fontconfig" ,fontconfig)
             ("freetype" ,freetype)
             ("gd" ,gd)
             ("icu4c" ,icu4c)
             ("ghostscript" ,ghostscript)
             ("libpng" ,libpng)
             ("libxaw" ,libxaw)
             ("libxt" ,libxt)
             ("perl" ,perl)
             ("pixman" ,pixman)
             ("poppler" ,poppler)
             ("pkg-config" ,pkg-config)
             ;; FIXME: Add interpreters fontforge and ruby,
             ;; once they are available.
             ("python" ,python-2) ; incompatible with Python 3 (print syntax)
             ("tcsh" ,tcsh)
             ("teckit" ,teckit)
             ("t1lib" ,t1lib)
             ("zlib" ,zlib)
             ("zziplib" ,zziplib)))
   (outputs '("out" "data"))
   (arguments
    `(#:out-of-source? #t
      #:configure-flags
       `("--disable-native-texlive-build"
         ;; Although the texmf-dist data is taken from texlive-texmf,
         ;; setting datarootdir is still useful:
         ;; "make install" creates symbolic links to scripts in this place.
         ,(string-append "--datarootdir=" (assoc-ref %outputs "data"))
         ,(string-append "--infodir=" (assoc-ref %outputs "out") "/share/info")
         ,(string-append "--mandir=" (assoc-ref %outputs "out") "/share/man")
         "--with-system-cairo"
         "--with-system-freetype2"
         "--with-system-gd"
         ;; "--with-system-graphite2"  ; requires cmake build system
         ;; "--with-system-harfbuzz"   ; requires --with-system-graphite2
         "--with-system-icu"
         "--with-system-libgs"
         "--with-system-libpng"
         "--with-system-pixman"
         "--with-system-poppler"
         "--with-system-t1lib"
         "--with-system-teckit"
         "--with-system-xpdf"
         "--with-system-zlib"
         "--with-system-zziplib")
      #:phases
       (alist-replace
        'configure
        (lambda* (#:key outputs #:allow-other-keys #:rest args)
         (let ((configure (assoc-ref %standard-phases 'configure)))
           (substitute* "utils/psutils/Makefile.in"
             (("/usr/bin/env perl") (which "perl")))
           (apply configure args)))
       (alist-cons-after
        'install 'postinst
         (lambda* (#:key inputs outputs #:allow-other-keys #:rest args)
           (let ((texlive-extra (assoc-ref inputs "texlive-extra-src"))
                 (texlive-texmf (assoc-ref inputs "texlive-texmf-src"))
                 (out (assoc-ref outputs "out"))
                 (data (assoc-ref outputs "data"))
                 (unpack (assoc-ref %standard-phases 'unpack))
                 (patch-source-shebangs
                   (assoc-ref %standard-phases 'patch-source-shebangs)))
             ;; Create symbolic links for the latex variants and their
             ;; man pages.
             (with-directory-excursion (string-append out "/bin/")
               (for-each symlink
               '("pdftex" "pdftex"   "xetex"   "luatex")
               '("latex"  "pdflatex" "xelatex" "lualatex")))
             (with-directory-excursion (string-append out "/share/man/man1/")
               (symlink "luatex.1" "lualatex.1"))
             ;; Delete texmf-dist from "data", since it will be reinstalled
             ;; from texlive-texmf.
             (system* "rm" "-r" (string-append data "/texmf-dist"))
             ;; Unpack texlive-extra and install tlpkg.
             (mkdir "texlive-extra")
             (with-directory-excursion "texlive-extra"
               (apply unpack (list #:source texlive-extra))
               (apply patch-source-shebangs (list #:source texlive-extra))
               (system* "mv" "tlpkg" data)
               (chdir ".."))
             ;; Unpack and install texlive-texmf.
             (mkdir "texlive-texmf")
             (with-directory-excursion "texlive-texmf"
               (apply unpack (list #:source texlive-texmf))
               (apply patch-source-shebangs (list #:source texlive-texmf))
               ;; Register "data" for kpathsea in texmf.cnf.
               (substitute* "texmf-dist/web2c/texmf.cnf"
                 (("TEXMFROOT = \\$SELFAUTOPARENT")
                 (string-append "TEXMFROOT = " data)))
               (system* "mv" "texmf-dist" data)
               (chdir ".."))
             ;; texmf.cnf must also be placed in "out", since kpsewhich does
             ;; not know about "data" until it has found this file.
             (mkdir (string-append out "/share/texmf-dist"))
             (mkdir (string-append out "/share/texmf-dist/web2c"))
             (copy-file (string-append data "/texmf-dist/web2c/texmf.cnf")
               (string-append out "/share/texmf-dist/web2c/texmf.cnf"))))
       (alist-cons-after 'patch-shebangs 'texconfig
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((out (assoc-ref outputs "out")))
             ;; Configure the texlive system; inspired from
             ;; http://slackbuilds.org/repository/13.37/office/texlive/
             (setenv "PATH" (string-append (getenv "PATH") ":" out "/bin"))
             (system* "updmap-sys" "--nohash" "--syncwithtrees")
             (system* "mktexlsr")
             (system* "fmtutil-sys" "--all")))
       %standard-phases)))))
   (synopsis "Tex Live, a package of the TeX typesetting system")
   (description
    "TeX Live provides a comprehensive TeX document production system.
It includes all the major TeX-related programs, macro packages, and fonts
that are free software, including support for many languages around the
world.")
   (license (license:fsf-free "http://tug.org/texlive/copying.html"))
   (home-page "http://www.tug.org/texlive/")))

(define-public rubber
  (package
    (name "rubber")
    (version "1.1")
    (source (origin
             (method url-fetch)
             (uri (list (string-append "https://launchpad.net/rubber/trunk/"
                                       version "/+download/rubber-"
                                       version ".tar.gz")
                        (string-append "http://ebeffara.free.fr/pub/rubber-"
                                       version ".tar.gz")))
             (sha256
              (base32
               "1xbkv8ll889933gyi2a5hj7hhh216k04gn8fwz5lfv5iz8s34gbq"))))
    (build-system gnu-build-system)
    (arguments '(#:tests? #f))                    ; no `check' target
    (inputs `(("texinfo" ,texinfo)
              ("python" ,python-2) ; incompatible with Python 3 (print syntax)
              ("which" ,which)))
    (home-page "https://launchpad.net/rubber")
    (synopsis "Rubber, a wrapper for LaTeX and friends")
    (description
     "Rubber is a program whose purpose is to handle all tasks related to the
compilation of LaTeX documents.  This includes compiling the document itself,
of course, enough times so that all references are defined, and running BibTeX
to manage bibliographic references.  Automatic execution of dvips to produce
PostScript documents is also included, as well as usage of pdfLaTeX to produce
PDF documents.")
    (license license:gpl2+)))
