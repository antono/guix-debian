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

(define-module (gnu system)
  #:use-module (guix store)
  #:use-module (guix monads)
  #:use-module (guix records)
  #:use-module (guix packages)
  #:use-module (guix derivations)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages package-management)
  #:use-module (gnu services)
  #:use-module (gnu services dmd)
  #:use-module (gnu services base)
  #:use-module (gnu system grub)
  #:use-module (gnu system shadow)
  #:use-module (gnu system linux)
  #:use-module (gnu system linux-initrd)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:export (operating-system
            operating-system?
            operating-system-services
            operating-system-packages
            operating-system-bootloader-entries
            operating-system-host-name
            operating-system-kernel
            operating-system-initrd
            operating-system-users
            operating-system-groups
            operating-system-packages
            operating-system-timezone
            operating-system-locale
            operating-system-services

            operating-system-profile-directory
            operating-system-derivation))

;;; Commentary:
;;;
;;; This module supports whole-system configuration.
;;;
;;; Code:

;; System-wide configuration.
;; TODO: Add per-field docstrings/stexi.
(define-record-type* <operating-system> operating-system
  make-operating-system
  operating-system?
  (kernel operating-system-kernel                 ; package
          (default linux-libre))
  (bootloader operating-system-bootloader         ; package
              (default grub))
  (bootloader-entries operating-system-bootloader-entries ; list
                      (default '()))
  (initrd operating-system-initrd                 ; monadic derivation
          (default (gnu-system-initrd)))

  (host-name operating-system-host-name)          ; string

  (file-systems operating-system-file-systems     ; list of fs
                (default '()))

  (users operating-system-users                   ; list of user accounts
         (default '()))
  (groups operating-system-groups                 ; list of user groups
          (default (list (user-group
                          (name "root")
                          (id 0))
                         (user-group
                          (name "users")
                          (id 100)
                          (members '("guest"))))))

  (packages operating-system-packages             ; list of (PACKAGE OUTPUT...)
            (default (list coreutils              ; or just PACKAGE
                           grep
                           sed
                           findutils
                           guile
                           bash
                           (@ (gnu packages dmd) dmd)
                           guix
                           tzdata)))

  (timezone operating-system-timezone)            ; string
  (locale   operating-system-locale)              ; string

  (services operating-system-services             ; list of monadic services
            (default %base-services)))



;;;
;;; Derivation.
;;;

(define* (union inputs
                #:key (guile (%guile-for-build)) (system (%current-system))
                (name "union"))
  "Return a derivation that builds the union of INPUTS.  INPUTS is a list of
input tuples."
  (define builder
    '(begin
       (use-modules (guix build union))

       (setvbuf (current-output-port) _IOLBF)
       (setvbuf (current-error-port) _IOLBF)

       (let ((output (assoc-ref %outputs "out"))
             (inputs (map cdr %build-inputs)))
         (format #t "building union `~a' with ~a packages...~%"
                 output (length inputs))
         (union-build output inputs))))

  (mlet %store-monad
      ((inputs (sequence %store-monad
                         (map (match-lambda
                               ((or ((? package? p)) (? package? p))
                                (mlet %store-monad
                                    ((drv (package->derivation p system)))
                                  (return `(,name ,drv))))
                               (((? package? p) output)
                                (mlet %store-monad
                                    ((drv (package->derivation p system)))
                                  (return `(,name ,drv ,output))))
                               (x
                                (return x)))
                              inputs))))
    (derivation-expression name builder
                           #:system system
                           #:inputs inputs
                           #:modules '((guix build union))
                           #:guile-for-build guile
                           #:local-build? #t)))

(define* (file-union files
                     #:key (inputs '()) (name "file-union"))
  "Return a derivation that builds a directory containing all of FILES.  Each
item in FILES must be a list where the first element is the file name to use
in the new directory, and the second element is the target file.

The subset of FILES corresponding to plain store files is automatically added
as an inputs; additional inputs, such as derivations, are taken from INPUTS."
  (mlet %store-monad ((inputs (lower-inputs inputs)))
    (let* ((outputs (append-map (match-lambda
                                 ((_ (? derivation? drv))
                                  (list (derivation->output-path drv)))
                                 ((_ (? derivation? drv) sub-drv ...)
                                  (map (cut derivation->output-path drv <>)
                                       sub-drv))
                                 (_ '()))
                                inputs))
           (inputs   (append inputs
                             (filter (match-lambda
                                      ((_ file)
                                       ;; Elements of FILES that are store
                                       ;; files and that do not correspond to
                                       ;; the output of INPUTS are considered
                                       ;; inputs (still here?).
                                       (and (direct-store-path? file)
                                            (not (member file outputs)))))
                                     files))))
      (derivation-expression name
                             `(let ((out (assoc-ref %outputs "out")))
                                (mkdir out)
                                (chdir out)
                                ,@(map (match-lambda
                                        ((name target)
                                         `(symlink ,target ,name)))
                                       files))

                             #:inputs inputs
                             #:local-build? #t))))

(define (links inputs)
  "Return a directory with symbolic links to all of INPUTS.  This is
essentially useful when one wants to keep references to all of INPUTS, be they
directories or regular files."
  (define builder
    '(begin
       (use-modules (srfi srfi-1))

       (let ((out (assoc-ref %outputs "out")))
         (mkdir out)
         (chdir out)
         (fold (lambda (file number)
                 (symlink file (number->string number))
                 (+ 1 number))
               0
               (map cdr %build-inputs))
         #t)))

  (mlet %store-monad ((inputs (lower-inputs inputs)))
    (derivation-expression "links" builder
                           #:inputs inputs
                           #:local-build? #t)))

(define* (etc-directory #:key
                        (locale "C") (timezone "Europe/Paris")
                        (accounts '())
                        (groups '())
                        (pam-services '())
                        (profile "/var/run/current-system/profile"))
  "Return a derivation that builds the static part of the /etc directory."
  (mlet* %store-monad
      ((services   (package-file net-base "etc/services"))
       (protocols  (package-file net-base "etc/protocols"))
       (rpc        (package-file net-base "etc/rpc"))
       (passwd     (passwd-file accounts))
       (shadow     (passwd-file accounts #:shadow? #t))
       (group      (group-file groups))
       (pam.d      (pam-services->directory pam-services))
       (login.defs (text-file "login.defs" "# Empty for now.\n"))
       (shells     (text-file "shells"            ; used by xterm and others
                              "\
/bin/sh
/run/current-system/bin/sh
/run/current-system/bin/bash\n"))
       (issue      (text-file "issue" "
This is an alpha preview of the GNU system.  Welcome.

This image features the GNU Guix package manager, which was used to
build it (http://www.gnu.org/software/guix/).  The init system is
GNU dmd (http://www.gnu.org/software/dmd/).

You can log in as 'guest' or 'root' with no password.
"))

       ;; TODO: Generate bashrc from packages' search-paths.
       (bashrc    (text-file* "bashrc"  "
export PS1='\\u@\\h\\$ '

export LC_ALL=\"" locale "\"
export TZ=\"" timezone "\"
export TZDIR=\"" tzdata "/share/zoneinfo\"

export PATH=$HOME/.guix-profile/bin:" profile "/bin:" profile "/sbin
export CPATH=$HOME/.guix-profile/include:" profile "/include
export LIBRARY_PATH=$HOME/.guix-profile/lib:" profile "/lib
alias ls='ls -p --color'
alias ll='ls -l'
"))

       (tz-file  (package-file tzdata
                               (string-append "share/zoneinfo/" timezone)))
       (files -> `(("services" ,services)
                   ("protocols" ,protocols)
                   ("rpc" ,rpc)
                   ("pam.d" ,(derivation->output-path pam.d))
                   ("login.defs" ,login.defs)
                   ("issue" ,issue)
                   ("shells" ,shells)
                   ("profile" ,(derivation->output-path bashrc))
                   ("localtime" ,tz-file)
                   ("passwd" ,passwd)
                   ("shadow" ,shadow)
                   ("group" ,group))))
    (file-union files
                #:inputs `(("net" ,net-base)
                           ("pam.d" ,pam.d)
                           ("bashrc" ,bashrc)
                           ("tzdata" ,tzdata))
                #:name "etc")))

(define (operating-system-profile-derivation os)
  "Return a derivation that builds the default profile of OS."
  ;; TODO: Replace with a real profile with a manifest.
  (union (operating-system-packages os)
         #:name "default-profile"))

(define (operating-system-profile-directory os)
  "Return the directory name of the default profile of OS."
  (mlet %store-monad ((drv (operating-system-profile-derivation os)))
    (return (derivation->output-path drv))))

(define (operating-system-derivation os)
  "Return a derivation that builds OS."
  (mlet* %store-monad
      ((services (sequence %store-monad
                           (cons (host-name-service
                                  (operating-system-host-name os))
                                 (operating-system-services os))))
       (pam-services ->
                     ;; Services known to PAM.
                     (delete-duplicates
                      (cons %pam-other-services
                            (append-map service-pam-services services))))

       (bash-file (package-file bash "bin/bash"))
       (dmd-file  (package-file (@ (gnu packages admin) dmd) "bin/dmd"))
       (accounts -> (cons (user-account
                            (name "root")
                            (password "")
                            (uid 0) (gid 0)
                            (comment "System administrator")
                            (home-directory "/root"))
                          (append (operating-system-users os)
                                  (append-map service-user-accounts
                                              services))))
       (groups   -> (append (operating-system-groups os)
                            (append-map service-user-groups services)))

       (profile-drv (operating-system-profile-derivation os))
       (profile ->  (derivation->output-path profile-drv))
       (etc-drv     (etc-directory #:accounts accounts #:groups groups
                                   #:pam-services pam-services
                                   #:locale (operating-system-locale os)
                                   #:timezone (operating-system-timezone os)
                                   #:profile profile-drv))
       (etc     ->  (derivation->output-path etc-drv))
       (dmd-conf  (dmd-configuration-file services etc))


       (boot     (text-file "boot"
                            (object->string
                             `(execl ,dmd-file "dmd"
                                     "--config" ,dmd-conf))))
       (kernel  ->  (operating-system-kernel os))
       (kernel-dir  (package-file kernel))
       (initrd      (operating-system-initrd os))
       (initrd-file -> (string-append (derivation->output-path initrd)
                                      "/initrd"))
       (entries ->  (list (menu-entry
                           (label (string-append
                                   "GNU system with "
                                   (package-full-name kernel)
                                   " (technology preview)"))
                           (linux kernel)
                           (linux-arguments `("--root=/dev/sda1"
                                              ,(string-append "--load=" boot)))
                           (initrd initrd-file))))
       (grub.cfg (grub-configuration-file entries))
       (extras   (links (delete-duplicates
                         (append (append-map service-inputs services)
                                 (append-map user-account-inputs accounts))))))
    (file-union `(("boot" ,boot)
                  ("kernel" ,kernel-dir)
                  ("initrd" ,initrd-file)
                  ("dmd.conf" ,dmd-conf)
                  ("profile" ,profile)
                  ("grub.cfg" ,grub.cfg)
                  ("etc" ,etc)
                  ("system-inputs" ,(derivation->output-path extras)))
                #:inputs `(("kernel" ,kernel)
                           ("initrd" ,initrd)
                           ("bash" ,bash)
                           ("profile" ,profile-drv)
                           ("etc" ,etc-drv)
                           ("system-inputs" ,extras))
                #:name "system")))

;;; system.scm ends here
