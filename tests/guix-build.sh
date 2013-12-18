# GNU Guix --- Functional package management for GNU
# Copyright © 2012, 2013 Ludovic Courtès <ludo@gnu.org>
#
# This file is part of GNU Guix.
#
# GNU Guix is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at
# your option) any later version.
#
# GNU Guix is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

#
# Test the `guix build' command-line utility.
#

guix build --version

# Should fail.
if guix build -e +;
then false; else true; fi

# Should fail because this is a source-less package.
if guix build -e '(@ (gnu packages bootstrap) %bootstrap-glibc)' -S
then false; else true; fi

# Should pass.
guix build -e '(@@ (gnu packages base) %bootstrap-guile)' |	\
    grep -e '-guile-'
guix build hello -d |				\
    grep -e '-hello-[0-9\.]\+\.drv$'

# Should all return valid log files.
drv="`guix build -d -e '(@@ (gnu packages base) %bootstrap-guile)'`"
out="`guix build -e '(@@ (gnu packages base) %bootstrap-guile)'`"
log="`guix build --log-file $drv`"
echo "$log" | grep log/.*guile.*drv
test -f "$log"
test "`guix build -e '(@@ (gnu packages base) %bootstrap-guile)' --log-file`" \
    = "$log"
test "`guix build --log-file guile-bootstrap`" = "$log"
test "`guix build --log-file $out`" = "$log"

# Should fail because the name/version combination could not be found.
if guix build hello-0.0.1 -n; then false; else true; fi

# Keep a symlink to the result, registered as a root.
result="t-result-$$"
guix build -r "$result"					\
    -e '(@@ (gnu packages base) %bootstrap-guile)'
test -x "$result/bin/guile"

# Should fail, because $result already exists.
if guix build -r "$result" -e '(@@ (gnu packages base) %bootstrap-guile)'
then false; else true; fi

rm -f "$result"

# Cross building.
guix build coreutils --target=mips64el-linux-gnu --dry-run --no-substitutes

# Parsing package names and versions.
guix build -n time		# PASS
guix build -n time-1.7		# PASS, version found
if guix build -n time-3.2;	# FAIL, version not found
then false; else true; fi
if guix build -n something-that-will-never-exist; # FAIL
then false; else true; fi

# Invoking a monadic procedure.
guix build -e "(begin
                 (use-modules (guix monads) (guix utils))
                 (lambda ()
                   (derivation-expression \"test\" '(mkdir %output))))" \
   --dry-run
