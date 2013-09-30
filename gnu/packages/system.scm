;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013 Cyril Roelandt <tipecaml@gmail.com>
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

(define-module (gnu packages system)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (gnu packages)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages guile)
  #:use-module ((gnu packages base)
                #:select (tar))
  #:use-module ((gnu packages compression)
                #:select (gzip))
  #:use-module (gnu packages pkg-config))

(define-public dmd
  (package
    (name "dmd")
    (version "-0.4")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://alpha.gnu.org/gnu/dmd/dmd-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "094ja3xvk9ljghhxmy39if67cfjd1hy6m4svnp399n0wpxvaryvy"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("--localstatedir=/var")))
    (inputs `(("pkg-config" ,pkg-config)
              ("guile" ,guile-2.0)))
    (synopsis "Daemon managing daemons")
    (description "'DMD' is a \"Daemon managing Daemons\" (or
\"Daemons-managing Daemon\"?)---i.e. a service manager that provides a
replacement for the service-managing capabilities of SysV-init (or any other
init) with a both powerful and beautiful dependency-based system with a
convenient interface.  It is intended for use on GNU/Hurd, but it is supposed
to work on every POSIX-like system where Guile is available.  In particular,
it has been tested on GNU/Linux.")
    (license gpl3+)
    (home-page "http://www.gnu.org/software/dmd/")))

(define-public dfc
  (package
   (name "dfc")
   (version "3.0.3")
   (source
    (origin
     (method url-fetch)
      (uri (string-append
            "http://projects.gw-computing.net/attachments/download/78/dfc-"
            version ".tar.gz"))
      (sha256
       (base32
        "1b4hfqv23l87cb37fxwzfk2sgspkyxpr3ig2hsd23hr6mm982j7z"))))
   (build-system cmake-build-system)
   (arguments '(#:tests? #f)) ; There are no tests.
   (home-page "http://projects.gw-computing.net/projects/dfc")
   (synopsis "Display file system space usage using graphs and colors")
   (description
    "dfc (df color) is a modern version of df.  It uses colors, draws pretty
graphs and can export its output to different formats.")
   (license bsd-3)))

(define-public htop
  (package
   (name "htop")
   (version "1.0.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://sourceforge/htop/"
                  version "/htop-" version ".tar.gz"))
            (sha256
             (base32
              "18fqrhvnm7h4c3939av8lpiwrwxbyw6hcly0jvq0vkjf0ixnaq7f"))))
   (build-system gnu-build-system)
   (inputs
    `(("ncurses" ,ncurses)))
   (home-page "http://htop.sourceforge.net/")
   (synopsis "Interactive process viewer")
   (description
    "This is htop, an interactive process viewer.  It is a text-mode
application (for console or X terminals) and requires ncurses.")
   (license gpl2)))

(define-public pies
  (package
    (name "pies")
    (version "1.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/pies/pies-"
                          version ".tar.bz2"))
      (sha256
       (base32
        "18w0dbg77i56cx1bwa789w0qi3l4xkkbascxcv2b6gbm0zmjg1g6"))))
    (build-system gnu-build-system)
    (home-page "http://www.gnu.org/software/pies/")
    (synopsis "Program invocation and execution supervisor")
    (description
     "The name Pies (pronounced \"p-yes\") stands for Program Invocation
and Execution Supervisor.  This utility starts and controls execution of
external programs, called components.  Each component is a stand-alone
program, which is executed in the foreground.  Upon startup, pies reads
the list of components from its configuration file, starts them, and
remains in the background, controlling their execution.  If any of the
components terminates, the default action of Pies is to restart it.
However, it can also be programmed to perform a variety of another
actions such as, e.g., sending mail notifications to the system
administrator, invoking another external program, etc.

Pies can be used for a wide variety of tasks.  Its most obious use is to
put in backgound a program which normally cannot detach itself from the
controlling terminal, such as, e.g., minicom.  It can launch and control
components of some complex system, such as Jabberd or MeTA1 (and it
offers much more control over them than the native utilities).  Finally,
it can replace the inetd utility!")
    (license gpl3+)))

(define-public inetutils
  (package
    (name "inetutils")
    (version "1.9.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnu/inetutils/inetutils-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0azzg6njgq79byl6960kb0wihfhhzf49snslhxgvi30ribgfpa82"))))
    (build-system gnu-build-system)
    (arguments `(#:patches (list (assoc-ref %build-inputs "patch/gets"))

                 ;; FIXME: `tftp.sh' relies on `netstat' from utils-linux,
                 ;; which is currently missing.
                 #:tests? #f))
    (inputs `(("patch/gets" ,(search-patch "diffutils-gets-undeclared.patch"))
              ("ncurses" ,ncurses)))
    (home-page "http://www.gnu.org/software/inetutils/")
    (synopsis "Basic networking utilities")
    (description
     "The GNU network utilities suite provides the following tools:
ftp(d), hostname, ifconfig, inetd, logger, ping, rcp, rexec(d),
rlogin(d), rsh(d), syslogd, talk(d), telnet(d), tftp(d), traceroute,
uucpd, and whois.")
    (license gpl3+)))

(define-public shadow
  (package
    (name "shadow")
    (version "4.1.5.1")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://pkg-shadow.alioth.debian.org/releases/shadow-"
                   version ".tar.bz2"))
             (sha256
              (base32
               "1yvqx57vzih0jdy3grir8vfbkxp0cl0myql37bnmi2yn90vk6cma"))))
    (build-system gnu-build-system)
    (arguments
     '(;; Assume System V `setpgrp (void)', which is the default on GNU
       ;; variants (`AC_FUNC_SETPGRP' is not cross-compilation capable.)
       #:configure-flags '("--with-libpam" "ac_cv_func_setpgrp_void=yes")

       #:phases (alist-cons-before
                 'build 'set-nscd-file-name
                 (lambda* (#:key inputs #:allow-other-keys)
                   ;; Use the right file name for nscd.
                   (let ((libc (assoc-ref inputs "libc")))
                     (substitute* "lib/nscd.c"
                       (("/usr/sbin/nscd")
                        (string-append libc "/sbin/nscd")))))
                 (alist-cons-after
                  'install 'remove-groups
                  (lambda* (#:key outputs #:allow-other-keys)
                    ;; Remove `groups', which is already provided by Coreutils.
                    (let* ((out (assoc-ref outputs "out"))
                           (bin (string-append out "/bin"))
                           (man (string-append out "/share/man/man1")))
                      (delete-file (string-append bin "/groups"))
                      (for-each delete-file (find-files man "^groups\\."))
                      #t))
                  %standard-phases))))

    (inputs (if (string-suffix? "-linux"
                                (or (%current-target-system)
                                    (%current-system)))
                `(("linux-pam" ,linux-pam))
                '()))
    (home-page "http://pkg-shadow.alioth.debian.org/")
    (synopsis "Authentication-related tools such as passwd, su, and login")
    (description
     "Shadow provides a number of authentication-related tools, including:
login, passwd, su, groupadd, and useradd.")

    ;; The `vipw' program is GPLv2+.
    ;; libmisc/salt.c is public domain.
    (license bsd-3)))

(define-public mingetty
  (package
    (name "mingetty")
    (version "1.08")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/mingetty/mingetty-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "05yxrp44ky2kg6qknk1ih0kvwkgbn9fbz77r3vci7agslh5wjm8g"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases (alist-replace 'configure
                               (lambda* (#:key inputs outputs
                                         #:allow-other-keys)
                                 (let* ((out    (assoc-ref outputs "out"))
                                        (man8   (string-append
                                                 out "/share/man/man8"))
                                        (sbin   (string-append out "/sbin"))
                                        (shadow (assoc-ref inputs "shadow"))
                                        (login  (string-append shadow
                                                               "/bin/login")))
                                   (substitute* "Makefile"
                                     (("^SBINDIR.*")
                                      (string-append "SBINDIR = " out
                                                     "/sbin\n"))
                                     (("^MANDIR.*")
                                      (string-append "MANDIR = " out
                                                     "/share/man/man8\n")))

                                   ;; Pick the right 'login' by default.
                                   (substitute* "mingetty.c"
                                     (("\"/bin/login\"")
                                      (string-append "\"" login "\"")))

                                   (mkdir-p sbin)
                                   (mkdir-p man8)))
                               %standard-phases)
       #:tests? #f))                              ; no tests
    (inputs `(("shadow" ,shadow)))

    (home-page "http://sourceforge.net/projects/mingetty")
    (synopsis "Getty for the text console")
    (description
     "Small console getty that is started on the Linux text console,
asks for a login name and then transfers over to 'login'.  It is extended to
allow automatic login and starting any app.")
    (license gpl2+)))

(define-public net-base
  (package
    (name "net-base")
    (version "5.1")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://ftp.de.debian.org/debian/pool/main/n/netbase/netbase_"
                   version ".tar.gz"))
             (sha256
              (base32
               "17l8xk2x632id5f9x9v5fs9wqc650hldd2lf3dh90r1zisj1ya8d"))))
    (build-system trivial-build-system)
    (arguments
     `(#:modules ((guix build utils))
       #:builder (begin
                   (use-modules (guix build utils)
                                (srfi srfi-26))

                   (let* ((source (assoc-ref %build-inputs "source"))
                          (tar    (assoc-ref %build-inputs "tar"))
                          (gzip   (assoc-ref %build-inputs "gzip"))
                          (output (assoc-ref %outputs "out"))
                          (etc    (string-append output "/etc")))
                     (setenv "PATH" (string-append gzip "/bin"))
                     (system* (string-append tar "/bin/tar") "xvf"
                              source)
                     (chdir ,(string-append "netbase-" version))
                     (mkdir-p etc)
                     (for-each copy-file
                               '("etc-services" "etc-protocols" "etc-rpc")
                               (map (cut string-append etc "/" <>)
                                    '("services" "protocols" "rpc")))
                     #t))))
    (native-inputs `(("tar" ,tar)
                     ("gzip" ,gzip)))
    (synopsis "IANA protocol, port, and RPC number assignments")
    (description
     "This package provides the /etc/services, /etc/protocols, and /etc/rpc
files, which contain information about the IANA-assigned port, protocol, and
ONC RPC numbers")
    (home-page "http://packages.debian.org/sid/netbase")
    (license gpl2)))
