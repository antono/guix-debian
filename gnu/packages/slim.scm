;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Guy Grant <gzg@riseup.net>
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

(define-module (gnu packages slim)
  #:use-module ((guix licenses)
		#:renamer (symbol-prefix-proc 'l:))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (guix packages)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages libpng)
  #:use-module (gnu packages libjpeg)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages linux))

(define-public slim
  (package
    (name "slim")
    (version "1.3.3")
    (source (origin
	     (method url-fetch)
	     (uri (string-append "mirror://sourceforge/project/slim.berlios/slim-"
				  version ".tar.gz"))
	     (sha256
	      (base32 "1fdvipj3658s8dm78djmfr8xhg6l8rr7kc4qcb34bjrnkkclhln1"))))
    (build-system cmake-build-system)
    (inputs `(("linux-pam" ,linux-pam)
	      ("libpng" ,libpng)
	      ("libjpeg" ,libjpeg)
	      ("freeglut" ,freeglut)
	      ("libxrandr" ,libxrandr)
	      ("libxrender" ,libxrender)
	      ("freetype" ,freetype)
	      ("fontconfig" ,fontconfig)
	      ("pkg-config" ,pkg-config)
	      ("libx11" ,libx11)
	      ("libxft" ,libxft)
	      ("libxmu" ,libxmu)
	      ("xauth" ,xauth)))
    (arguments
     '(#:phases (alist-cons-before
		 'configure 'set-new-etc-location
		 (lambda _
		   (substitute* "CMakeLists.txt"
		     (("/etc")
		      (string-append
		       (assoc-ref %outputs "out") "/etc"))))
		 %standard-phases)
       #:configure-flags '("-DUSE_PAM=yes" "-DUSE_CONSOLEKIT=no")
       #:tests? #f))
    (home-page "http://www.slim.berlios.de/")
    (synopsis "Desktop-independent graphcal login manager for X11")
    (description
     "SLiM is a Desktop-independent graphical login manager for X11, derived
from Login.app. It aims to be light and simple, although completely configurable
through themes and an option file; is suitable for machines on which remote login
functionalities are not needed.

Features included: PNG and XFT support for alpha transparency and antialiased fonts,
External themes support, Configurable runtime options: X server -- login / shutdown / reboot
commands, Single (GDM-like) or double (XDM-like) input control, Can load predefined user at
startup, Configurable welcome / shutdown messages, Random theme selection")
    (license l:gpl2)))
