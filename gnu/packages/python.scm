;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013 Nikita Karetnikov <nikita@karetnikov.org>
;;; Copyright © 2013, 2014 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2014 Eric Bavier <bavier@member.fsf.org>
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

(define-module (gnu packages python)
  #:use-module ((guix licenses)
                #:select (asl2.0 bsd-3 bsd-style cc0 expat x11 x11-style
                          gpl2 gpl2+ lgpl2.1+
                          psfl public-domain))
  #:use-module ((guix licenses) #:select (zlib)
                                #:renamer (symbol-prefix-proc 'license:))
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gdbm)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages openssl)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages sqlite)
  #:use-module (gnu packages zip)
  #:use-module (gnu packages multiprecision)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system python)
  #:use-module (guix build-system trivial))

(define-public python-2
  (package
    (name "python")
    (version "2.7.6")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://www.python.org/ftp/python/"
                          version "/Python-" version ".tar.xz"))
      (patches (list (search-patch "python-libffi-mips-n32-fix.patch")))
      (patch-flags '("-p0"))
      (sha256
       (base32
        "18gnpyh071dxa0rv3silrz92jw9qpblswzwv4gzqcwxzz20qxmhz"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
;;       258 tests OK.
;;       103 tests failed:
;;          test_bz2 test_distutils test_file test_file2k test_popen2
;;          test_shutil test_signal test_site test_slice test_smtplib
;;          test_smtpnet test_socket test_socketserver test_softspace
;;          test_sort test_sqlite test_ssl test_startfile test_str
;;          test_strftime test_string test_stringprep test_strop test_strptime
;;          test_strtod test_struct test_structmembers test_structseq
;;          test_subprocess test_sunaudiodev test_sundry test_symtable
;;          test_syntax test_sys test_sys_setprofile test_sys_settrace
;;          test_sysconfig test_tarfile test_tcl test_telnetlib test_tempfile
;;          test_textwrap test_thread test_threaded_import
;;          test_threadedtempfile test_threading test_threading_local
;;          test_threadsignals test_time test_timeout test_tk test_tokenize
;;          test_tools test_trace test_traceback test_transformer
;;          test_ttk_guionly test_ttk_textonly test_tuple test_typechecks
;;          test_ucn test_unary test_undocumented_details test_unicode
;;          test_unicode_file test_unicodedata test_univnewlines
;;          test_univnewlines2k test_unpack test_urllib test_urllib2
;;          test_urllib2_localnet test_urllib2net test_urllibnet test_urlparse
;;          test_userdict test_userlist test_userstring test_uu test_uuid
;;          test_wait3 test_wait4 test_warnings test_wave test_weakref
;;          test_weakset test_whichdb test_winreg test_winsound test_with
;;          test_wsgiref test_xdrlib test_xml_etree test_xml_etree_c
;;          test_xmllib test_xmlrpc test_xpickle test_xrange test_zipfile
;;          test_zipfile64 test_zipimport test_zipimport_support test_zlib
;;       31 tests skipped:
;;          test_aepack test_al test_applesingle test_ascii_formatd test_bsddb
;;          test_bsddb185 test_bsddb3 test_cd test_cl test_codecmaps_cn
;;          test_codecmaps_hk test_codecmaps_jp test_codecmaps_kr
;;          test_codecmaps_tw test_ctypes test_curses test_dl test_gdb test_gl
;;          test_imageop test_imgfile test_ioctl test_kqueue
;;          test_linuxaudiodev test_macos test_macostools test_msilib
;;          test_multiprocessing test_ossaudiodev test_pep277
;;          test_scriptpackages
;;       7 skips unexpected on linux2:
;;          test_ascii_formatd test_bsddb test_bsddb3 test_ctypes test_gdb
;;          test_ioctl test_multiprocessing
;;    One of the typical errors:
;;    test_unicode
;;    test test_unicode crashed -- <type 'exceptions.OSError'>: [Errno 2] No such file or directory
       #:test-target "test"
       #:configure-flags
        (let ((bz2 (assoc-ref %build-inputs "bzip2"))
              (gdbm (assoc-ref %build-inputs "gdbm"))
              (libffi (assoc-ref %build-inputs "libffi"))
              (openssl (assoc-ref %build-inputs "openssl"))
              (readline (assoc-ref %build-inputs "readline"))
              (zlib (assoc-ref %build-inputs "zlib")))
         (list "--enable-shared"                  ; allow embedding
               "--with-system-ffi"                ; build ctypes
               (string-append "CPPFLAGS="
                "-I" bz2 "/include "
                "-I" gdbm "/include "
                "-I" openssl "/include "
                "-I" readline "/include "
                "-I" zlib "/include")
               (string-append "LDFLAGS="
                "-L" bz2 "/lib "
                "-L" gdbm "/lib "
                "-L" libffi "/lib "
                "-L" openssl "/lib "
                "-L" readline "/lib "
                "-L" zlib "/lib")))

        #:modules ((guix build gnu-build-system)
                   (guix build utils)
                   (guix build rpath)
                   (srfi srfi-26))
        #:imported-modules ((guix build gnu-build-system)
                            (guix build utils)
                            (guix build rpath))

        #:phases
        (alist-cons-after
         'strip 'add-lib-to-runpath
         (lambda* (#:key outputs #:allow-other-keys)
           (let* ((out (assoc-ref outputs "out"))
                  (lib (string-append out "/lib")))
             ;; Add LIB to the RUNPATH of all the executables.
             (with-directory-excursion out
               (for-each (cut augment-rpath <> lib)
                         (find-files "bin" ".*")))))
         (alist-cons-before
          'configure 'patch-lib-shells
          (lambda _
            ;; Filter for existing files, since some may not exist in all
            ;; versions of python that are built with this recipe.
            (substitute* (filter file-exists?
                                 '("Lib/subprocess.py"
                                   "Lib/popen2.py"
                                   "Lib/distutils/tests/test_spawn.py"
                                   "Lib/test/test_subprocess.py"))
              (("/bin/sh") (which "sh"))))
          (alist-cons-before
           'check 'pre-check
           (lambda _
             ;; 'Lib/test/test_site.py' needs a valid $HOME
             (setenv "HOME" (getcwd)))
           %standard-phases)))))
    (inputs
     `(("bzip2" ,bzip2)
       ("gdbm" ,gdbm)
       ("libffi" ,libffi)                         ; for ctypes
       ("openssl" ,openssl)
       ("readline" ,readline)
       ("zlib" ,zlib)
       ("patchelf" ,patchelf)))                   ; for (guix build rpath)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (native-search-paths
     (list (search-path-specification
            (variable "PYTHONPATH")
            (directories '("lib/python2.7/site-packages")))))
    (home-page "http://python.org")
    (synopsis
     "Python, a high-level dynamically-typed programming language")
    (description
     "Python is a remarkably powerful dynamic programming language that
is used in a wide variety of application domains.  Some of its key
distinguishing features include: clear, readable syntax; strong
introspection capabilities; intuitive object orientation; natural
expression of procedural code; full modularity, supporting hierarchical
packages; exception-based error handling; and very high level dynamic
data types.")
    (license psfl)))

(define-public python
  (package (inherit python-2)
    (version "3.3.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.python.org/ftp/python/"
                                  version "/Python-" version ".tar.xz"))
              (patches (list (search-patch "python-fix-tests.patch")
                             (search-patch "python-libffi-mips-n32-fix.patch")))
              (patch-flags '("-p0"))
              (sha256
               (base32
                "1rdncc7g8g6f3lfdg33rli1yffbiq8z283xy4f5ksl1l8i49psdb"))))
    (arguments
     (let ((args `(#:modules ((guix build gnu-build-system)
                              (guix build utils)
                             (srfi srfi-1)
                              (srfi srfi-26))
                   ,@(package-arguments python-2))))
       (substitute-keyword-arguments args
         ((#:tests? _) #t))))
    (native-search-paths
     (list (search-path-specification
            (variable "PYTHONPATH")
            (directories '("lib/python3.3/site-packages")))))))

(define-public python-wrapper
  (package (inherit python)
    (name "python-wrapper")
    (source #f)
    (build-system trivial-build-system)
    (inputs `(("python" ,python)))
    (arguments
     `(#:modules ((guix build utils))
       #:builder
         (begin
           (use-modules (guix build utils))
           (let ((bin (string-append (assoc-ref %outputs "out") "/bin"))
                 (python (string-append (assoc-ref %build-inputs "python") "/bin/")))
                (mkdir-p bin)
                (for-each
                  (lambda (old new)
                    (symlink (string-append python old)
                             (string-append bin "/" new)))
                  `("python3", "pydoc3", "idle3")
                  `("python",  "pydoc",  "idle"))))))
    (description (string-append (package-description python)
     "\n\nThis wrapper package provides symbolic links to the python binaries
      without version suffix."))))


(define-public python-pytz
  (package
    (name "python-pytz")
    (version "2013b")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://launchpad.net/pytz/main/" version
                          "/+download/pytz-" version ".tar.bz2"))
      (sha256
       (base32
        "19giwgfcrg0nr1gdv49qnmf2jb2ilkcfc7qyqvfpz4dp0p64ksv5"))))
    (build-system python-build-system)
    (arguments `(#:tests? #f)) ; no test target
    (home-page "https://launchpad.net/pytz")
    (synopsis "The Python timezone library.")
    (description
     "This library allows accurate and cross platform timezone calculations
using Python 2.4 or higher and provides access to the Olson timezone database.")
    (license x11)))

(define-public python2-pytz
  (package-with-python2 python-pytz))


(define-public python-babel
  (package
    (name "python-babel")
    (version "1.3")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/B/Babel/Babel-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0bnin777lc53nxd1hp3apq410jj5wx92n08h7h4izpl4f4sx00lz"))))
    (build-system python-build-system)
    (inputs
     `(("python-pytz" ,python-pytz)
       ("python-setuptools" ,python-setuptools)))
    (arguments `(#:tests? #f)) ; no test target
    (home-page "http://babel.pocoo.org/")
    (synopsis
     "Tools for internationalizing Python applications")
    (description
     "Babel is composed of two major parts:
- tools to build and work with gettext message catalogs
- a Python interface to the CLDR (Common Locale Data Repository), providing
access to various locale display names, localized number and date formatting,
etc. ")
    (license bsd-3)))

(define-public python2-babel
  (package-with-python2 python-babel))

(define-public python-lockfile
  (package
    (name "python-lockfile")
    (version "0.9.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://pypi.python.org/packages/source/l/lockfile/"
                           "lockfile-" version ".tar.gz"))
       (sha256
        (base32
         "0iwif7i84gwpvrnpv4brshdk8j6l77smvknm8k3bg77mj6f5ini3"))))
    (build-system python-build-system)
    (arguments '(#:test-target "check"))
    (home-page "http://code.google.com/p/pylockfile/")
    (synopsis "Platform-independent file locking module")
    (description
     "The lockfile package exports a LockFile class which provides a simple
API for locking files.")
    (license expat)))

(define-public python2-lockfile
  (package-with-python2 python-lockfile))

(define-public python-mock
  (package
    (name "python-mock")
    (version "1.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://pypi.python.org/packages/source/m/mock/"
                           "mock-" version ".tar.gz"))
       (sha256
        (base32
         "0kzlsbki6q0awf89rc287f3aj8x431lrajf160a70z0ikhnxsfdq"))))
    (build-system python-build-system)
    (arguments '(#:test-target "check"))
    (home-page "http://code.google.com/m/mock/")
    (synopsis "A Python Mocking and Patching Library for Testing")
    (description
     "Mock is a library for testing in Python.  It allows you to replace parts
of your system under test with mock objects and make assertions about how they
have been used.")
    (license expat)))

(define-public python2-mock
  (package-with-python2 python-mock))


(define-public python-setuptools
  (package
    (name "python-setuptools")
    (version "1.1.4")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/s/setuptools/setuptools-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0hl9sa5xr9bi2ifq51wy1bawsjv5nzvpbac7m9z1ciz778874csf"))))
    (build-system python-build-system)
    (arguments
     `(#:tests? #f))
         ;;FIXME: test_sdist_with_utf8_encoded_filename fails in
         ;; /tmp/nix-build-python2-setuptools-1.1.4.drv-0/setuptools-1.1.4/setuptools/tests/test_sdist.py"
         ;; line 354
         ;; The tests pass with Python 2.7.5.
    (home-page "https://pypi.python.org/pypi/setuptools")
    (synopsis
     "Library designed to facilitate packaging Python projects")
    (description
     "Setuptools is a fully-featured, stable library designed to facilitate
packaging Python projects, where packaging includes:
Python package and module definitions,
distribution package metadata,
test hooks,
project installation,
platform-specific details,
Python 3 support.")
    (license psfl)))

(define-public python2-setuptools
  (package-with-python2 python-setuptools))


(define-public python-pycrypto
  (package
    (name "python-pycrypto")
    (version "2.6.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/p/"
                          "pycrypto/pycrypto-" version ".tar.gz"))
      (sha256
       (base32
        "0g0ayql5b9mkjam8hym6zyg6bv77lbh66rv1fyvgqb17kfc1xkpj"))))
    (build-system python-build-system)
    (native-inputs
     `(("python-setuptools" ,python-setuptools)))
    (inputs
     `(("python" ,python)
       ("gmp" ,gmp)))
    (arguments
     `(#:phases
       (alist-cons-before
        'build 'set-build-env
        ;; pycrypto runs an autoconf configure script behind the scenes
        (lambda _
          (setenv "CONFIG_SHELL" (which "bash")))
        %standard-phases)))
    (home-page "http://www.pycrypto.org/")
    (synopsis "Cryptographic modules for Python")
    (description
     "Pycrypto is a collection of both secure hash functions (such as SHA256
and RIPEMD160), and various encryption algorithms (AES, DES, RSA, ElGamal,
etc.). The package is structured to make adding new modules easy.")
    (license public-domain)))

(define-public python-keyring
  (package
    (name "python-keyring")
    (version "3.8")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/k/"
                          "keyring/keyring-" version ".zip"))
      (sha256
       (base32
        "1vxazfbcwggyfyramh55shkxs08skhpqrkm6lrrjnygnm8c1l2zg"))))
    (build-system python-build-system)
    (native-inputs
     `(("unzip" ,unzip)
       ("python-setuptools" ,python-setuptools)
       ("python-mock" ,python-mock)))
    (inputs
     `(("python-pycrypto" ,python-pycrypto)))
    (arguments
     `(#:tests? #f                      ;TODO: tests require pytest
       #:phases
       (alist-replace
        'unpack
        (lambda _
          (let ((unzip (string-append (assoc-ref %build-inputs "unzip")
                                      "/bin/unzip"))
                (source (assoc-ref %build-inputs "source")))
            (and (zero? (system* unzip source))
                 (chdir (string-append "keyring-" ,version)))))
        %standard-phases)))
    (home-page "http://bitbucket.org/kang/python-keyring-lib")
    (synopsis "Store and access your passwords safely")
    (description
     "The Python keyring lib provides a easy way to access the system keyring
service from python. It can be used in any application that needs safe
password storage.")
    ;; "MIT" and PSF dual license
    (license x11)))

(define-public python-six
  (package
    (name "python-six")
    (version "1.7.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/s/"
                          "six/six-" version ".tar.gz"))
      (sha256
       (base32
        "164rns26aqfqx2hwi0qq3scl50s69japn0fvgvrjsbyg7r1mxf67"))))
    (build-system python-build-system)
    (inputs
     `(("python-setuptools" ,python-setuptools)))
    (home-page "http://pypi.python.org/pypi/six/")
    (synopsis "Python 2 and 3 compatibility utilities")
    (description
     "Six is a Python 2 and 3 compatibility library. It provides utility
functions for smoothing over the differences between the Python versions with
the goal of writing Python code that is compatible on both Python versions.
Six supports every Python version since 2.5. It is contained in only one
Python file, so it can be easily copied into your project.")
    (license x11)))

(define-public python-dateutil-2
  (package
    (name "python-dateutil")
    (version "2.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/p/"
                          name "/" name "-" version ".tar.gz"))
      (sha256
       (base32
        "0s74ad6r789810s10dxgvaf48ni6adac2icrdad34zxygqq6bj7f"))))
    (build-system python-build-system)
    (inputs
     `(("python-setuptools" ,python-setuptools)
       ("python-six" ,python-six)))
    (home-page "http://labix.org/python-dateutil")
    (synopsis "Extensions to the standard datetime module")
    (description
     "The dateutil module provides powerful extensions to the standard
datetime module, available in Python 2.3+.")
    (license bsd-3)))

(define-public python2-dateutil-2
  (package-with-python2 python-dateutil-2))

(define-public python-dateutil
  (package
    (name "python-dateutil")
    (version "1.5") ; last version for python < 3
    (source
     (origin
      (method url-fetch)
      (uri (string-append "http://labix.org/download/python-dateutil/"
                          "python-dateutil-" version ".tar.gz"))
      (sha256
       (base32
        "0fqfglhy5khbvsipr3x7m6bcaqljh8xl5cw33vbfxy7qhmywm2n0"))))
    (build-system python-build-system)
    (inputs
     `(("python-setuptools" ,python-setuptools)))
    (home-page "http://labix.org/python-dateutil")
    (synopsis "Extensions to the standard datetime module")
    (description
     "The dateutil module provides powerful extensions to the standard
datetime module, available in Python 2.3+.")
    (license psfl)))

(define-public python2-dateutil
  (package-with-python2 python-dateutil))

(define-public python-parsedatetime
  (package
    (name "python-parsedatetime")
    (version "1.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/p/"
                          "parsedatetime/parsedatetime-" version ".tar.gz"))
      (sha256
       (base32
        "1zcj0pzxvpl4j2ma9awmpkfxldybi2kjaahjjpmgfbg5cxwcjsqv"))))
    (build-system python-build-system)
    (native-inputs
     `(("python-setuptools" ,python-setuptools)))
    (arguments `(#:tests? #f))          ;no test target
    (home-page "http://github.com/bear/parsedatetime/")
    (synopsis
     "Parse human-readable date/time text")
    (description
     "Parse human-readable date/time text")
    (license asl2.0)))

(define-public python-tzlocal
  (package
    (name "python-tzlocal")
    (version "1.1.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/t/"
                          "tzlocal/tzlocal-" version ".zip"))
      (sha256
       (base32
        "1m3y918c3chf41fwg2bx4w42bqsjzn3dyvvcmwwy13c8gj6zssv9"))))
    (build-system python-build-system)
    (native-inputs
     `(("unzip" ,unzip)
       ("python-setuptools" ,python-setuptools)))
    (inputs `(("python-pytz" ,python-pytz)))
    (arguments
     `(#:phases
       (alist-replace
        'unpack
        (lambda _
          (let ((unzip (string-append (assoc-ref %build-inputs "unzip")
                                      "/bin/unzip"))
                (source (assoc-ref %build-inputs "source")))
            (and (zero? (system* unzip source))
                 (chdir (string-append "tzlocal-" ,version)))))
        %standard-phases)))
    (home-page "https://github.com/regebro/tzlocal")
    (synopsis
     "tzinfo object for the local timezone")
    (description
     "Tzlocal returns a tzinfo object with the local timezone information.
This module attempts to fix a glaring hole in pytz, that there is no way to
get the local timezone information, unless you know the zoneinfo name, and
under several distributions that's hard or impossible to figure out.")
    (license cc0)))


(define-public python2-pysqlite
  (package
    (name "python2-pysqlite")
    (version "2.6.3a")                            ; see below
    (source
     (origin
      (method url-fetch)
      ;; During the switch from code.google.com to pypi.python.org, the 2.6.3
      ;; tarball was modified, but the version number was kept:
      ;; <https://lists.gnu.org/archive/html/guix-devel/2014-02/msg00077.html>.
      ;; Here we want to refer to the pypi-hosted 2.6.3 tarball.
      (uri (string-append
            "https://pypi.python.org/packages/source/p/pysqlite/pysqlite-"
            "2.6.3" ".tar.gz"))
      (sha256
       (base32
        "13djzgnbi71znjjyaw4nybg6smilgszcid646j5qav7mdchkb77y"))))
    (build-system python-build-system)
    (inputs
     `(("sqlite" ,sqlite)))
    (arguments
     `(#:python ,python-2 ; incompatible with Python 3
       #:tests? #f)) ; no test target
    (home-page "https://pypi.python.org/pypi/pysqlite")
    (synopsis "SQLite bindings for Python")
    (description
     "Pysqlite provides SQLite bindings for Python that comply to the
Database API 2.0T.")
    (license license:zlib)))


(define-public python2-mechanize
  (package
    (name "python2-mechanize")
    (version "0.2.5")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/m/mechanize/mechanize-"
                          version ".tar.gz"))
      (sha256
       (base32
        "0rj7r166i1dyrq0ihm5rijfmvhs8a04im28lv05c0c3v206v4rrf"))))
    (build-system python-build-system)
    (inputs
     `(("python2-setuptools" ,python2-setuptools)))
    (arguments
     `(#:python ,python-2 ; apparently incompatible with Python 3
       #:tests? #f))
         ;; test fails with message
         ;; AttributeError: 'module' object has no attribute 'test_pullparser'
         ;; (python-3.3.2) or
         ;; AttributeError: 'module' object has no attribute 'test_urllib2_localnet'
         ;; (python-2.7.5).
         ;; The source code is from March 2011 and probably not up-to-date
         ;; with respect to python unit tests.
    (home-page "http://wwwsearch.sourceforge.net/mechanize/")
    (synopsis
     "Stateful programmatic web browsing in Python")
    (description
     "Mechanize implements stateful programmatic web browsing in Python,
after Andy Lester’s Perl module WWW::Mechanize.")
    (license (bsd-style "file://COPYING"
                        "See COPYING in the distribution."))))


(define-public python-simplejson
  (package
    (name "python-simplejson")
    (version "3.3.0")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/s/simplejson/simplejson-"
                          version ".tar.gz"))
      (sha256
       (base32
        "07wsry5j44l5zzm74l4j2bvasiq8n5m32f31n2p7c68i5vc6p2ks"))))
    (build-system python-build-system)
    (home-page "http://simplejson.readthedocs.org/en/latest/")
    (synopsis
     "Json library for Python")
    (description
     "JSON (JavaScript Object Notation) is a subset of JavaScript syntax
 (ECMA-262 3rd edition) used as a lightweight data interchange format.

Simplejson exposes an API familiar to users of the standard library marshal
and pickle modules.  It is the externally maintained version of the json
library contained in Python 2.6, but maintains compatibility with Python 2.5
and (currently) has significant performance advantages, even without using
the optional C extension for speedups.  Simplejson is also supported on
Python 3.3+.")
    (license x11)))

(define-public python2-simplejson
  (package-with-python2 python-simplejson))


(define-public python2-pyicu
  (package
    (name "python2-pyicu")
    (version "1.5")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/P/PyICU/PyICU-"
                          version ".tar.gz"))
      (sha256
       (base32
        "011vwflpir8wvh48mvi6d9a7vw0f43bkwv0w6bzxbzmvz20ax5vm"))))
    (build-system python-build-system)
    (inputs
     `(("icu4c" ,icu4c)))
    (arguments
     `(#:python ,python-2 ; Python 3 works also, but needs special care for
                          ; linking with libpython3.3m
       #:tests? #f)) ; no check target
    (home-page "http://pyicu.osafoundation.org/")
    (synopsis
     "Python extension wrapping the ICU C++ API.")
    (description
     "PyICU is a python extension wrapping the ICU C++ API.")
    (license x11)))

(define-public python2-dogtail
  ;; Python 2 only, as it leads to "TabError: inconsistent use of tabs and
  ;; spaces in indentation" with Python 3.
  (package
    (name "python2-dogtail")
    (version "0.8.2")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "https://fedorahosted.org/released/dogtail/dogtail-"
                   version ".tar.gz"))
             (sha256
              (base32
               "1yc4cg7ip87z15gyd4wy2vzbywrjc52a3m8r8gqy2b50d65llcg1"))))
    (build-system python-build-system)
    (arguments `(#:python ,python-2
                 #:tests? #f))                    ; invalid command "test"
    (home-page "https://fedorahosted.org/dogtail/")
    (synopsis "GUI test tool and automation framework written in ​Python")
    (description
     "dogtail is a GUI test tool and automation framework written in Python.
It uses Accessibility (a11y) technologies to communicate with desktop
applications. dogtail scripts are written in Python and executed like any
other Python program.")
    (license gpl2+)))

(define-public python2-empy
  (package
    (name "python2-empy")
    (version "3.3")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://www.alcyone.com/software/empy/empy-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "01g8mmkfnvjdmlhsihwyx56lrg7r5m5d2fg6mnxsvy6g0dnl69f6"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2
       #:phases (alist-replace
                 'check
                 (lambda _
                   (zero? (system* "./test.sh")))
                 %standard-phases)))
    (home-page "http://www.alcyone.com/software/empy/")
    (synopsis "Templating system for Python")
    (description
     "EmPy is a system for embedding Python expressions and statements in
template text; it takes an EmPy source file, processes it, and produces
output.  This is accomplished via expansions, which are special signals to the
EmPy system and are set off by a special prefix (by default the at sign, @).
EmPy can expand arbitrary Python expressions and statements in this way, as
well as a variety of special forms.  Textual data not explicitly delimited in
this way is sent unaffected to the output, allowing Python to be used in
effect as a markup language.  Also supported are callbacks via hooks,
recording and playback via diversions, and dynamic, chainable filters.  The
system is highly configurable via command line options and embedded
commands.")
    (license lgpl2.1+)))

(define-public python2-element-tree
  (package
    (name "python2-element-tree")
    (version "1.2.6")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://effbot.org/media/downloads/elementtree-"
                    version "-20050316.tar.gz"))
              (sha256
               (base32
                "016bphqnlg0l4vslahhw4r0aanw95bpypy65r1i1acyb2wj5z7dj"))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2                       ; seems to be part of Python 3
       #:tests? #f))                            ; no 'test' sub-command
    (synopsis "Toolkit for XML processing in Python")
    (description
     "ElementTree is a Python library supporting lightweight XML processing.")
    (home-page "http://effbot.org/zone/element-index.htm")
    (license (x11-style "http://docs.python.org/2/license.html"
                        "Like \"CWI LICENSE AGREEMENT FOR PYTHON \
0.9.0 THROUGH 1.2\"."))))

(define-public python2-pybugz
  (package
    (name "python2-pybugz")
    (version "0.6.11")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://bits.liquidx.net/projects/pybugz/pybugz-"
                    version ".tar.gz"))
              (sha256
               (base32
                "17ni00p08gp5lkxlrrcnvi3x09fmajnlbz4da03qcgl9q21ym4jd"))
              (patches (map search-patch
                            (list "pybugz-stty.patch"
                                  "pybugz-encode-error.patch")))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2                         ; SyntaxError with Python 3
       #:tests? #f))                              ; no 'test' sub-command
    (inputs `(("element-tree" ,python2-element-tree)))
    (synopsis "Python and command-line interface to Bugzilla")
    (description
     "PyBugz is a Python library and command-line tool to query the Bugzilla
bug tracking system.  It is meant as an aid to speed up interaction with the
bug tracker.")
    (home-page "http://www.liquidx.net/pybugz/")
    (license gpl2)))

(define-public python-enum34
  (package
    (name "python-enum34")
    (version "1.0")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/e/"
                          "enum34/enum34-" version ".tar.gz"))
      (sha256
       (base32
        "0dg6mpg9n4g9diyrbnbb5vd9d1qw9f265zwhknqy0mxh0cvmjjrq"))))
    (build-system python-build-system)
    (inputs
     `(("python-setuptools" ,python-setuptools)))
    (arguments
     `(#:phases
       (alist-replace
        'check
        (lambda _ (zero? (system* "python" "enum/test_enum.py")))
        %standard-phases)))
    (home-page "https://pypi.python.org/pypi/enum34")
    (synopsis "Backported Python 3.4 Enum")
    (description
     "Enum34 is the new Python stdlib enum module available in Python 3.4
backported for previous versions of Python from 2.4 to 3.3.")
    (license bsd-3)))

(define-public python-parse-type
  (package
    (name "python-parse-type")
    (version "0.3.4")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/p/"
                          "parse_type/parse_type-" version ".tar.gz"))
      (sha256
       (base32
        "0iv1c34npr4iynwpgv1vkjx9rjd18a85ir8c01gc5f7wp8iv7l1x"))))
    (build-system python-build-system)
    (inputs
     `(("python-setuptools" ,python-setuptools)
       ("python-six" ,python-six)
       ("python-parse" ,python-parse)
       ("python-enum34" ,python-enum34))) ;required for python<3.4
    (arguments '(#:tests? #f))            ;TODO: tests require pytest
    (home-page "https://github.com/jenisys/parse_type")
    (synopsis "Extended parse module")
    (description
     "Parse_type extends the python parse module.")
    (license bsd-3)))

(define-public python-parse
  (package
    (name "python-parse")
    (version "1.6.4")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://pypi.python.org/packages/source/p/"
                          "parse/parse-" version ".tar.gz"))
      (sha256
       (base32
        "0m30q64l6szl7s9mhvqy64w2fdhdn8lb91fmacjiwbv3479cmk57"))))
    (build-system python-build-system)
    (arguments
     `(#:phases
       (alist-replace
        'check
        (lambda _ (zero? (system* "python" "test_parse.py")))
        %standard-phases)))
    (home-page "https://github.com/r1chardj0n3s/parse")
    (synopsis "Parse strings")
    (description
     "Parse strings using a specification based on the Python format()
syntax.")
    (license x11)))


(define-public scons
  (package
    (name "scons")
    (version "2.1.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/scons/scons-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "07cjn4afb2cljjrd3cr7xf062qq58z8q96f58z6yplhdyqafsfa1"))))
    (build-system python-build-system)
    (arguments
     ;; With Python 3.x, fails to build with a syntax error.
     `(#:python ,python-2
       #:tests? #f))                       ; no 'python setup.py test' command
    (home-page "http://scons.org/")
    (synopsis "Software construction tool written in Python")
    (description
     "SCons is a software construction tool.  Think of SCons as an improved,
cross-platform substitute for the classic Make utility with integrated
functionality similar to autoconf/automake and compiler caches such as ccache.
In short, SCons is an easier, more reliable and faster way to build
software.")
    (license x11)))

(define-public behave
  (package
    (name "behave")
    (version "1.2.4")
    (source (origin
             (method url-fetch)
             (uri (string-append "https://pypi.python.org/packages/source/b/"
                                 name "/" name "-" version ".tar.gz"))
             (sha256
              (base32
               "1v2rfy8xnf0rk7cj4cgr7lam4015d458i7bg0xqs9czfv6njlm14"))))
    (build-system python-build-system)
    (inputs
     `(("python-setuptools" ,python-setuptools)
       ("python-six" ,python-six)
       ("python-enum43" ,python-enum34)
       ("python-parse" ,python-parse)
       ("python-parse-type" ,python-parse-type)))
    (arguments `(#:tests? #f))          ;TODO: tests require nose>=1.3 and
                                        ;PyHamcrest>=1.8
    (home-page "http://github.com/behave/behave")
    (synopsis "Python behavior-driven development")
    (description
     "Behave is a tool for behavior-driven development in python.
Behavior-driven development (or BDD) is an agile software development
technique that encourages collaboration between developers, QA and
non-technical or business participants in a software project.  Behave uses
tests written in a natural language style, backed up by Python code.")
    (license x11)))
