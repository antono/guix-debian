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

(define-module (gnu packages package-management)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:select (gpl3+))
  #:use-module (gnu packages)
  #:use-module (gnu packages guile)
  #:use-module ((gnu packages compression) #:select (bzip2 gzip))
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages graphviz)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages texinfo))

(define-public guix-0.6
  (package
    (name "guix")
    (version "0.6")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://alpha.gnu.org/gnu/guix/guix-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "01xw51wizhsk827w4xp79k2b6dxjaviw04r6rbrb85qdxnwg6k9n"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags (list
                          "--localstatedir=/var"
                          "--sysconfdir=/etc"
                          (string-append "--with-libgcrypt-prefix="
                                         (assoc-ref %build-inputs
                                                    "libgcrypt")))
       #:phases (alist-cons-before
                 'configure 'copy-bootstrap-guile
                 (lambda* (#:key system inputs #:allow-other-keys)
                   (define (copy arch)
                     (let ((guile  (assoc-ref inputs
                                              (string-append "boot-guile/"
                                                             arch)))
                           (target (string-append "gnu/packages/bootstrap/"
                                                  arch "-linux/"
                                                  "/guile-2.0.9.tar.xz")))
                       (copy-file guile target)))

                   (copy "i686")
                   (copy "x86_64")
                   (copy "mips64el")
                   #t)
                 %standard-phases)))
    (inputs
     (let ((boot-guile (lambda (arch hash)
                         (origin
                          (method url-fetch)
                          (uri (string-append
                                "http://alpha.gnu.org/gnu/guix/bootstrap/"
                                arch "-linux"
                                "/20131110/guile-2.0.9.tar.xz"))
                          (sha256 hash)))))
       `(("bzip2" ,bzip2)
         ("gzip" ,gzip)

         ("sqlite" ,sqlite)
         ("libgcrypt" ,libgcrypt)
         ("guile" ,guile-2.0)
         ("pkg-config" ,pkg-config)

         ("boot-guile/i686"
          ,(boot-guile "i686"
                       (base32
                        "0im800m30abgh7msh331pcbjvb4n02smz5cfzf1srv0kpx3csmxp")))
         ("boot-guile/x86_64"
          ,(boot-guile "x86_64"
                       (base32
                        "1w2p5zyrglzzniqgvyn1b55vprfzhgk8vzbzkkbdgl5248si0yq3")))
         ("boot-guile/mips64el"
          ,(boot-guile "mips64el"
                       (base32
                        "0fzp93lvi0hn54acc0fpvhc7bvl0yc853k62l958cihk03q80ilr"))))))
    (home-page "http://www.gnu.org/software/guix")
    (synopsis "Functional package manager for installed software packages and versions")
    (description
     "GNU Guix is a functional package manager for the GNU system, and is
also a distribution thereof.  It includes a virtual machine image. Besides
the usual package management features, it also supports transactional
upgrades and roll-backs, per-user profiles, and much more. It is based on the
Nix package manager.")
    (license gpl3+)))

(define-public guix
  ;; Development version of Guix.
  (let ((commit "0ae8c15"))
    (package (inherit guix-0.6)
      (version (string-append "0.6." commit))
      (source (origin
                (method git-fetch)
                (uri (git-reference
                      (url "git://git.sv.gnu.org/guix.git")
                      (commit commit)
                      (recursive? #t)))
                (sha256
                 (base32
                  "1y6mwzwsjdxbfibqypb55dix371rifhfz0bygfr8k868lcdsawic"))))
      (arguments
       (substitute-keyword-arguments (package-arguments guix-0.6)
         ((#:phases phases)
          `(alist-cons-before
            'configure 'bootstrap
            (lambda _
              ;; Comment out `git' invocations, since 'git-fetch' provides us
              ;; with a checkout that includes sub-modules.
              (substitute* "bootstrap"
                (("git ")
                 "true git "))

              ;; Keep a list of the files already available under nix/...
              (call-with-output-file "ls-R"
                (lambda (port)
                  (for-each (lambda (file)
                              (format port "~a~%" file))
                            (find-files "nix" ""))))

              ;; ... and use that as a substitute to 'git ls-tree'.
              (substitute* "nix/sync-with-upstream"
                (("git ls-tree HEAD -- [[:graph:]]+")
                 "cat ls-R"))

              ;; Make sure 'msgmerge' can modify the PO files.
              (for-each (lambda (po)
                          (chmod po #o666))
                        (find-files "." "\\.po$"))

              (zero? (system* "./bootstrap")))
            ,phases))))
      (native-inputs
       `(("autoconf" ,(autoconf-wrapper))
         ("automake" ,automake)
         ("gettext" ,gnu-gettext)
         ("texinfo" ,texinfo)
         ("graphviz" ,graphviz)
         ,@(package-native-inputs guix-0.6))))))
