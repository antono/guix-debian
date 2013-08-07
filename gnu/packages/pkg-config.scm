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

(define-module (gnu packages pkg-config)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:export (pkg-config))

;; This is the "primitive" pkg-config package.  People should use `pkg-config'
;; (see below) rather than `%pkg-config', but we export `%pkg-config' so that
;; `fold-packages' finds it.
(define-public %pkg-config
  (package
   (name "pkg-config")
   (version "0.27.1")
   (source (origin
            (method url-fetch)
            (uri (string-append
                  "http://pkgconfig.freedesktop.org/releases/pkg-config-"
                  version ".tar.gz"))
            (sha256
             (base32
              "05wc5nwkqz7saj2v33ydmz1y6jdg659dll4jjh91n41m63gx0qsg"))))
   (build-system gnu-build-system)
   (arguments `(#:configure-flags '("--with-internal-glib")))
   (native-search-paths
    (list (search-path-specification
           (variable "PKG_CONFIG_PATH")
           (directories '("lib/pkgconfig" "lib64/pkgconfig"
                          "share/pkgconfig")))))
   (home-page "http://www.freedesktop.org/wiki/Software/pkg-config")
   (license gpl2+)
   (synopsis "a helper tool used when compiling applications and
libraries")
   (description
    "pkg-config is a helper tool used when compiling applications and
libraries.  It helps you insert the correct compiler options on the
command line so an application can use gcc -o test test.c `pkg-config
--libs --cflags glib-2.0` for instance, rather than hard-coding values
on where to find glib (or other libraries). It is language-agnostic, so
it can be used for defining the location of documentation tools, for
instance.")))

(define (cross-pkg-config target)
  "Return a pkg-config for TARGET, essentially just a wrapper called
`TARGET-pkg-config', as `configure' scripts like it."
  ;; See <http://www.flameeyes.eu/autotools-mythbuster/pkgconfig/cross-compiling.html>
  ;; for details.
  (package (inherit %pkg-config)
    (name (string-append (package-name %pkg-config) "-" target))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder (begin
                   (use-modules (guix build utils))

                   (let* ((out  (assoc-ref %outputs "out"))
                          (bin  (string-append out "/bin"))
                          (prog (string-append ,target "-pkg-config"))
                          (native
                           (string-append
                            (assoc-ref %build-inputs "pkg-config")
                            "/bin/pkg-config")))

                     (mkdir-p bin)

                     ;; Create a `TARGET-pkg-config' -> `pkg-config' symlink.
                     ;; This satisfies the pkg.m4 macros, which use
                     ;; AC_PROG_TOOL to determine the `pkg-config' program
                     ;; name.
                     (symlink native (string-append bin "/" prog))))))
    (native-inputs `(("pkg-config" ,%pkg-config)))

    ;; Ignore native inputs, and set `PKG_CONFIG_PATH' for target inputs.
    (native-search-paths '())
    (search-paths (package-native-search-paths %pkg-config))))

(define (pkg-config-for-target target)
  "Return a pkg-config package for TARGET, which may be either #f for a native
build, or a GNU triplet."
  (if target
      (cross-pkg-config target)
      %pkg-config))

;; This hack allows us to automatically choose the native or the cross
;; `pkg-config' depending on whether it's being used in a cross-build
;; environment or not.
(define-syntax pkg-config
  (identifier-syntax (pkg-config-for-target (%current-target-system))))
