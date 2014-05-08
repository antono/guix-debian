;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
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

(define-module (gnu packages gtk)
  #:use-module ((guix licenses)
                #:renamer (symbol-prefix-proc 'license:))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages libjpeg)
  #:use-module (gnu packages libpng)
  #:use-module (gnu packages libtiff)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages xorg))

(define-public atk
  (package
   (name "atk")
   (version "2.10.0")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/" name "/"
                                (string-take version 4) "/" name "-"
                                version ".tar.xz"))
            (sha256
             (base32
              "1c2hbg66wfvibsz2ia0ri48yr62751fn950i97c53j3b0fjifsb3"))))
   (build-system gnu-build-system)
   (inputs `(("glib" ,glib)
             ("gobject-introspection" ,gobject-introspection)))
   (native-inputs `(("pkg-config" ,pkg-config)))
   (synopsis "GNOME accessibility toolkit")
   (description
    "ATK provides the set of accessibility interfaces that are implemented
by other toolkits and applications. Using the ATK interfaces, accessibility
tools have full access to view and control running applications.")
   (license license:lgpl2.0+)
   (home-page "https://developer.gnome.org/atk/")))

(define-public cairo
  (package
   (name "cairo")
   (version "1.12.16")
   (source (origin
            (method url-fetch)
            (uri (string-append "http://cairographics.org/releases/cairo-"
                                version ".tar.xz"))
            (sha256
             (base32
              "0inqwsylqkrzcjivdirkjx5nhdgxbdc62fq284c3xppinfg9a195"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("fontconfig" ,fontconfig)
      ("freetype" ,freetype)
      ("glib" ,glib)
      ("libpng" ,libpng)
      ("libx11" ,libx11)
      ("libxext" ,libxext)
      ("libxrender" ,libxrender)
      ("pixman" ,pixman)))
   (inputs
    `(("ghostscript" ,ghostscript)
      ("libspectre" ,libspectre)
      ("poppler" ,poppler)
      ("xextproto" ,xextproto)
      ("zlib" ,zlib)))
   (native-inputs
     `(("pkg-config" ,pkg-config)
      ("python" ,python-wrapper)))
    (arguments
      `(#:tests? #f)) ; see http://lists.gnu.org/archive/html/bug-guix/2013-06/msg00085.html
   (synopsis "2D graphics library")
   (description
    "Cairo is a 2D graphics library with support for multiple output devices.
Currently supported output targets include the X Window System (via both
Xlib and XCB), Quartz, Win32, image buffers, PostScript, PDF, and SVG file
output. Experimental backends include OpenGL, BeOS, OS/2, and DirectFB.

Cairo is designed to produce consistent output on all output media while
taking advantage of display hardware acceleration when available
eg. through the X Render Extension).

The cairo API provides operations similar to the drawing operators of
PostScript and PDF. Operations in cairo including stroking and filling cubic
Bézier splines, transforming and compositing translucent images, and
antialiased text rendering. All drawing operations can be transformed by any
affine transformation (scale, rotation, shear, etc.)")
   (license license:lgpl2.1) ; or Mozilla Public License 1.1
   (home-page "http://cairographics.org/")))

(define-public harfbuzz
  (package
   (name "harfbuzz")
   (version "0.9.22")
   (source (origin
            (method url-fetch)
            (uri (string-append "http://www.freedesktop.org/software/harfbuzz/release/harfbuzz-"
                                version ".tar.bz2"))
            (sha256
             (base32
              "1nkimwadri6v2kzrmz8y0crmy59gw0kg4i4f6cc786bngs0815lq"))))
   (build-system gnu-build-system)
   (inputs
    `(("cairo" ,cairo)
      ("icu4c" ,icu4c)))
   (native-inputs
     `(("pkg-config" ,pkg-config)
      ("python" ,python-wrapper)))
   (synopsis "opentype text shaping engine")
   (description
    "HarfBuzz is an OpenType text shaping engine.")
   (license (license:x11-style "file://COPYING"
                       "See 'COPYING' in the distribution."))
   (home-page "http://www.freedesktop.org/wiki/Software/HarfBuzz/")))

(define-public pango
  (package
   (name "pango")
   (version "1.34.1")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/pango/1.34/pango-"
                                version ".tar.xz"))
            (sha256
             (base32
              "0k7662qix7zzh7mf6ikdj594n8jpbfm25z8swz64zbm86kgk1shs"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("cairo" ,cairo)
      ("harfbuzz" ,harfbuzz)))
   (inputs
    `(("gobject-introspection" ,gobject-introspection)
      ("zlib" ,zlib)))
   (native-inputs
    `(("pkg-config" ,pkg-config)))
   (synopsis "GNOME text and font handling library")
   (description
    "Pango is the core text and font handling library used in GNOME
applications. It has extensive support for the different writing systems
used throughout the world.")
   (license license:lgpl2.0+)
   (home-page "https://developer.gnome.org/pango/")))


(define-public gtksourceview
  (package
    (name "gtksourceview")
    (version "2.10.5") ; This is the last version which builds against gtk+2
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/gtksourceview/"
                                  (string-take version 4) "/gtksourceview-"
                                  version ".tar.bz2"))
              (sha256
               (base32
                "07hrabhpl6n8ajz10s0d960jdwndxs87szxyn428mpxi8cvpg1f5"))))
    (build-system gnu-build-system)
    (inputs
     `(("gtk" ,gtk+-2)
       ("libxml2" ,libxml2)
       ;; These two are needed only to allow the tests to run successfully.
       ("xorg-server" ,xorg-server)
       ("shared-mime-info" ,shared-mime-info)))
    (native-inputs
      `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (arguments
     `(#:phases
       ;; Unfortunately, some of the tests in "make check" are highly dependent
       ;; on the environment therefore, some black magic is required.
       (alist-cons-before
        'check 'start-xserver
        (lambda* (#:key inputs #:allow-other-keys)
          (let ((xorg-server (assoc-ref inputs "xorg-server"))
                (mime (assoc-ref inputs "shared-mime-info")))

            ;; There must be a running X server and make check doesn't start one.
            ;; Therefore we must do it.
            (system (format #f "~a/bin/Xvfb :1 &" xorg-server))
            (setenv "DISPLAY" ":1")

            ;; The .lang files must be found in $XDG_DATA_HOME/gtksourceview-2.0
            (system "ln -s gtksourceview gtksourceview-2.0")
            (setenv "XDG_DATA_HOME" (getcwd))

            ;; Finally, the mimetypes must be available.
            (setenv "XDG_DATA_DIRS" (string-append mime "/share/")) ))
        %standard-phases)))
    (synopsis "Widget that extends the standard GTK+ 2.x 'GtkTextView' widget")
    (description
     "GtkSourceView is a portable C library that extends the standard GTK+
framework for multiline text editing with support for configurable syntax
highlighting, unlimited undo/redo, search and replace, a completion framework,
printing and other features typical of a source code editor.")
    (license license:lgpl2.0+)
    (home-page "https://developer.gnome.org/gtksourceview/")))

(define-public gdk-pixbuf
  (package
   (name "gdk-pixbuf")
   (version "2.28.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/gdk-pixbuf/2.28/gdk-pixbuf-"
                                version ".tar.xz"))
            (sha256
             (base32
              "05s6ksvy1yan6h6zny9n3bmvygcnzma6ljl6i0z9cci2xg116c8q"))))
   (build-system gnu-build-system)
   (inputs
    `(("glib" ,glib)
      ("gobject-introspection", gobject-introspection)
      ("libjpeg" ,libjpeg)
      ("libpng" ,libpng)
      ("libtiff" ,libtiff)))
   (native-inputs
     `(("pkg-config" ,pkg-config)))
   (synopsis "GNOME image loading and manipulation library")
   (description
    "GdkPixbuf is a library for image loading and manipulation developed
in the GNOME project.")
   (license license:lgpl2.0+)
   (home-page "https://developer.gnome.org/gdk-pixbuf/")))

(define-public at-spi2-core
  (package
   (name "at-spi2-core")
   (version "2.10.0")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/" name "/"
                                (string-take version 4) "/" name "-"
                                version ".tar.xz"))
            (sha256
             (base32
              "1ns44yibdgcwzwri7sr075hfs5rh5lgxkh71247a0822az3mahcn"))))
   (build-system gnu-build-system)
   (inputs `(("dbus" ,dbus)
             ("glib" ,glib)
             ("libxi" ,libxi)
             ("libxtst" ,libxtst)))
   (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
   (arguments
    `(#:tests? #f)) ; FIXME: dbind/dbtest fails; one should disable tests in
                    ; a more fine-grained way.
   (synopsis "Assistive Technology Service Provider Interface, core components")
   (description
    "The Assistive Technology Service Provider Interface, core components,
is part of the GNOME accessibility project.")
   (license license:lgpl2.0+)
   (home-page "https://projects.gnome.org/accessibility/")))

(define-public at-spi2-atk
  (package
   (name "at-spi2-atk")
   (version "2.10.0")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/" name "/"
                                (string-take version 4) "/" name "-"
                                version ".tar.xz"))
            (sha256
             (base32
              "150sqc21difazqd53llwfdaqnwfy73bic9hia41xpfy9kcpzz9yy"))))
   (build-system gnu-build-system)
   (inputs `(("atk" ,atk)
             ("at-spi2-core" ,at-spi2-core)
             ("dbus" ,dbus)
             ("glib" ,glib)))
   (native-inputs
     `(("pkg-config" ,pkg-config)))
   (arguments
    `(#:tests? #f)) ; FIXME: droute/droute-test fails; one should disable
                    ; tests in a more fine-grained way.
   (synopsis "Assistive Technology Service Provider Interface, ATK bindings")
   (description
    "The Assistive Technology Service Provider Interface
is part of the GNOME accessibility project.")
   (license license:lgpl2.0+)
   (home-page "https://projects.gnome.org/accessibility/")))

(define-public gtk+-2
  (package
   (name "gtk+")
   (version "2.24.21")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/" name "/"
                                (string-take version 4) "/" name "-"
                                version ".tar.xz"))
            (sha256
             (base32
              "1qyw73pr9ryqhir2h1kbx3vm70km4dg2fxrgkrdlpv0rvlb94bih"))))
   (build-system gnu-build-system)
   (propagated-inputs
    `(("atk" ,atk)
      ("gdk-pixbuf" ,gdk-pixbuf)
      ("pango" ,pango)))
   (native-inputs
    `(("perl" ,perl)
      ("pkg-config" ,pkg-config)
      ("python-wrapper" ,python-wrapper)))
   (arguments
    `(#:phases
      (alist-cons-before
       'configure 'disable-tests
       (lambda _
         ;; FIXME: re-enable tests requiring an X server
         (substitute* "gtk/Makefile.in"
           (("SUBDIRS = theme-bits . tests") "SUBDIRS = theme-bits .")))
      %standard-phases)))
   (synopsis "Cross-platform toolkit for creating graphical user interfaces")
   (description
    "GTK+, or the GIMP Toolkit, is a multi-platform toolkit for creating
graphical user interfaces. Offering a complete set of widgets, GTK+ is
suitable for projects ranging from small one-off tools to complete
application suites.")
   (license license:lgpl2.0+)
   (home-page "http://www.gtk.org/")))

(define-public gtk+
  (package (inherit gtk+-2)
   (version "3.10.1")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/gtk+/"
                                (string-take version 4) "/gtk+-"
                                version ".tar.xz"))
            (sha256
             (base32
              "1f3a7r3z7i9xh5imlfpfcgyydzkj2fnd0v6ylvqxij0yzfbnhbn1"))))
   (propagated-inputs
    `(("at-spi2-atk" ,at-spi2-atk)
      ("atk" ,atk)
      ("gdk-pixbuf" ,gdk-pixbuf)
      ("libxi" ,libxi)
      ("libxinerama" ,libxinerama)
      ("pango" ,pango)))
   (inputs
    `(("gobject-introspection" ,gobject-introspection)
      ("libxml2" ,libxml2)))
   (native-inputs
     `(("perl" ,perl)
      ("pkg-config" ,pkg-config)
      ("python-wrapper" ,python-wrapper)
      ("xorg-server" ,xorg-server)))
   (arguments
    `(#:modules ((guix build gnome)
                 (guix build gnu-build-system)
                 (guix build utils))
      #:imported-modules ((guix build gnome)
                          (guix build gnu-build-system)
                          (guix build utils))
      #:phases
      (alist-replace
       'configure
       (lambda* (#:key inputs #:allow-other-keys #:rest args)
         (let ((configure (assoc-ref %standard-phases 'configure)))
           ;; Disable most tests, failing in the chroot with the message:
           ;; D-Bus library appears to be incorrectly set up; failed to read
           ;; machine uuid: Failed to open "/etc/machine-id": No such file or
           ;; directory.
           ;; See the manual page for dbus-uuidgen to correct this issue.
           (substitute* "testsuite/Makefile.in"
            (("SUBDIRS = gdk gtk a11y css reftests") "SUBDIRS = gdk"))

	   ;; We need to tell GIR where it can find some of the required .gir
           ;; files.
           (substitute* "gdk/Makefile.in"
            (("--add-include-path=../gdk")
             (string-append
              "--add-include-path=../gdk"
              " --add-include-path=" (gir-directory inputs "gdk-pixbuf")
              " --add-include-path=" (gir-directory inputs "pango")))
            (("--includedir=\\.")
             (string-append "--includedir=."
              " --includedir=" (gir-directory inputs "gdk-pixbuf")
              " --includedir=" (gir-directory inputs "pango"))))

           (substitute* "gtk/Makefile.in"
            (("--add-include-path=../gdk")
             (string-append "--add-include-path=../gdk"
              " --add-include-path=" (gir-directory inputs "atk")
              " --add-include-path=" (gir-directory inputs "gdk-pixbuf")
              " --add-include-path=" (gir-directory inputs "pango")))
            (("--includedir=../gdk")
             (string-append "--includedir=../gdk"
              " --includedir=" (gir-directory inputs "atk")
              " --includedir=" (gir-directory inputs "gdk-pixbuf")
              " --includedir=" (gir-directory inputs "pango"))))
           (apply configure args)))
       %standard-phases)))))

;;;
;;; Guile bindings.
;;;

(define-public guile-cairo
  (package
    (name "guile-cairo")
    (version "1.4.1")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://download.gna.org/guile-cairo/guile-cairo-"
                   version
                   ".tar.gz"))
             (sha256
              (base32
               "1f5nd9n46n6cwfl1byjml02q3y2hgn7nkx98km1czgwarxl7ws3x"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-before
                 'configure 'set-module-directory
                 (lambda* (#:key outputs #:allow-other-keys)
                   ;; Install modules under $out/share/guile/site/2.0.
                   (let ((out (assoc-ref outputs "out")))
                     (substitute* "Makefile.in"
                       (("scmdir = ([[:graph:]]+).*" _ value)
                        (string-append "scmdir = " value "/2.0\n")))
                     (substitute* "cairo/Makefile.in"
                       (("moduledir = ([[:graph:]]+).*" _ value)
                        (string-append "moduledir = "
                                       "$(prefix)/share/guile/site/2.0/cairo\n'")))))
                 (alist-cons-after
                  'install 'install-missing-file
                  (lambda* (#:key outputs #:allow-other-keys)
                    ;; By default 'vector-types.scm' is not installed, so do
                    ;; it here.
                    (let ((out (assoc-ref outputs "out")))
                      (copy-file "cairo/vector-types.scm"
                                 (string-append out "/share/guile/site/2.0"
                                                "/cairo/vector-types.scm"))))
                  %standard-phases))))
    (inputs
     `(("guile-lib" ,guile-lib)
       ("expat" ,expat)
       ("cairo" ,cairo)
       ("guile" ,guile-2.0)))
    (native-inputs
      `(("pkg-config" ,pkg-config)))
    (home-page "http://www.nongnu.org/guile-cairo/")
    (synopsis "Cairo bindings for GNU Guile")
    (description
     "Guile-Cairo wraps the Cairo graphics library for Guile Scheme.
Guile-Cairo is complete, wrapping almost all of the Cairo API.  It is API
stable, providing a firm base on which to do graphics work.  Finally, and
importantly, it is pleasant to use.  You get a powerful and well-maintained
graphics library with all of the benefits of Scheme: memory management,
exceptions, macros, and a dynamic programming environment.")
    (license license:lgpl3+)))


;;;
;;; C++ bindings.
;;;

(define-public cairomm
  (package
    (name "cairomm")
    (version "1.10.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://cairographics.org/releases/cairomm-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "13rrp96px95m6xnvmsaqb0wcqsnizg3bz334k0yhlyxf7v29d386"))))
    (build-system gnu-build-system)
    (arguments
     ;; The examples lack -lcairo.
     '(#:make-flags '("LDFLAGS=-lcairo")))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("libsigc++" ,libsigc++)
       ("freetype" ,freetype)
       ("fontconfig" ,fontconfig)
       ("cairo" ,cairo)))
    (home-page "http://cairographics.org/")
    (synopsis "C++ bindings to the Cairo 2D graphics library")
    (description
     "Cairomm provides a C++ programming interface to the Cairo 2D graphics
library.")
    (license license:lgpl2.0+)))

(define-public pangomm
  (package
    (name "pangomm")
    (version "2.34.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/pangomm/2.34/pangomm-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "0hcyvv7c5zmivprdam6cp111i6hn2y5jsxzk00m6j9pncbzvp0hf"))))
    (build-system gnu-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("cairo" ,cairo)
       ("cairomm" ,cairomm)
       ("glibmm" ,glibmm)
       ("pango" ,pango)))
    (home-page "http://www.pango.org/")
    (synopsis "C++ interface to the Pango text rendering library")
    (description
     "Pangomm provides a C++ programming interface to the Pango text rendering
library.")
    (license license:lgpl2.1+)))

(define-public atkmm
  (package
    (name "atkmm")
    (version "2.22.7")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/atkmm/2.22/atkmm-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "06zrf2ymml2dzp53sss0d4ch4dk9v09jm8rglnrmwk4v81mq9gxz"))))
    (build-system gnu-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("glibmm" ,glibmm) ("atk" ,atk)))
    (home-page "http://www.gtkmm.org")
    (synopsis "C++ interface to the ATK accessibility library")
    (description
     "ATKmm provides a C++ programming interface to the ATK accessibility
toolkit.")
    (license license:lgpl2.1+)))

(define-public gtkmm
  (package
    (name "gtkmm")
    (version "3.9.16")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/gtkmm/3.9/gtkmm-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "0yf8wwv4w02p70nrxsbs0nhm0w4gkn2wggdjygd8vif062anf1rs"))))
    (build-system gnu-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("pangomm" ,pangomm)
       ("cairomm" ,cairomm)
       ("atkmm" ,atkmm)
       ("gtk+" ,gtk+)
       ("glibmm" ,glibmm)))
    (home-page "http://gtkmm.org/")
    (synopsis
     "C++ interface to the GTK+ graphical user interface library")
    (description
     "gtkmm is the official C++ interface for the popular GUI library GTK+.
Highlights include typesafe callbacks, and a comprehensive set of widgets that
are easily extensible via inheritance.  You can create user interfaces either
in code or with the Glade User Interface designer, using libglademm.  There's
extensive documentation, including API reference and a tutorial.")
    (license license:lgpl2.1+)))


(define-public gtkmm-2
  (package (inherit gtkmm)
    (version "2.24.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/gtkmm/"
                                 (string-take version 4) "/gtkmm-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "0gcm91sc1a05c56kzh74l370ggj0zz8nmmjvjaaxgmhdq8lpl369"))))
    (propagated-inputs
     `(("pangomm" ,pangomm)
       ("cairomm" ,cairomm)
       ("atkmm" ,atkmm)
       ("gtk+" ,gtk+-2)
       ("glibmm" ,glibmm)))))
