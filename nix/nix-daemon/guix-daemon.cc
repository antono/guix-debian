/* GNU Guix --- Functional package management for GNU
   Copyright (C) 2012, 2013, 2014 Ludovic Courtès <ludo@gnu.org>

   This file is part of GNU Guix.

   GNU Guix is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or (at
   your option) any later version.

   GNU Guix is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.  */

#include <config.h>

#include <types.hh>
#include "shared.hh"
#include <globals.hh>
#include <util.hh>

#include <gcrypt.h>

#include <stdlib.h>
#include <argp.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <strings.h>
#include <exception>

/* Variables used by `nix-daemon.cc'.  */
volatile ::sig_atomic_t blockInt;
char **argvSaved;

using namespace nix;

/* Entry point in `nix-daemon.cc'.  */
extern void run (Strings args);


/* Command-line options.  */

const char *argp_program_version =
  "guix-daemon (" PACKAGE_NAME ") " PACKAGE_VERSION;
const char *argp_program_bug_address = PACKAGE_BUGREPORT;

static char doc[] =
"guix-daemon -- perform derivation builds and store accesses\
\v\
This program is a daemon meant to run in the background.  It serves \
requests sent over a Unix-domain socket.  It accesses the store, and \
builds derivations on behalf of its clients.";

#define GUIX_OPT_SYSTEM 1
#define GUIX_OPT_DISABLE_CHROOT 2
#define GUIX_OPT_BUILD_USERS_GROUP 3
#define GUIX_OPT_CACHE_FAILURES 4
#define GUIX_OPT_LOSE_LOGS 5
#define GUIX_OPT_DISABLE_LOG_COMPRESSION 6
#define GUIX_OPT_DISABLE_STORE_OPTIMIZATION 7
#define GUIX_OPT_IMPERSONATE_LINUX_26 8
#define GUIX_OPT_DEBUG 9
#define GUIX_OPT_CHROOT_DIR 10
#define GUIX_OPT_LISTEN 11
#define GUIX_OPT_NO_SUBSTITUTES 12
#define GUIX_OPT_NO_BUILD_HOOK 13
#define GUIX_OPT_GC_KEEP_OUTPUTS 14
#define GUIX_OPT_GC_KEEP_DERIVATIONS 15

static const struct argp_option options[] =
  {
    { "system", GUIX_OPT_SYSTEM, "SYSTEM", 0,
      "Assume SYSTEM as the current system type" },
    { "cores", 'c', "N", 0,
      "Use N CPU cores to build each derivation; 0 means as many as available" },
    { "max-jobs", 'M', "N", 0,
      "Allow at most N build jobs" },
    { "disable-chroot", GUIX_OPT_DISABLE_CHROOT, 0, 0,
      "Disable chroot builds"
#ifndef HAVE_CHROOT
      " (chroots are not supported in this configuration, so "
      "this option has no effect)"
#endif
    },
    { "chroot-directory", GUIX_OPT_CHROOT_DIR, "DIR", 0,
      "Add DIR to the build chroot"
#ifndef HAVE_CHROOT
      " (chroots are not supported in this configuration, so "
      "this option has no effect)"
#endif
    },
    { "build-users-group", GUIX_OPT_BUILD_USERS_GROUP, "GROUP", 0,
      "Perform builds as a user of GROUP" },
    { "no-substitutes", GUIX_OPT_NO_SUBSTITUTES, 0, 0,
      "Do not use substitutes" },
    { "no-build-hook", GUIX_OPT_NO_BUILD_HOOK, 0, 0,
      "Do not use the 'build hook'" },
    { "cache-failures", GUIX_OPT_CACHE_FAILURES, 0, 0,
      "Cache build failures" },
    { "lose-logs", GUIX_OPT_LOSE_LOGS, 0, 0,
      "Do not keep build logs" },
    { "disable-log-compression", GUIX_OPT_DISABLE_LOG_COMPRESSION, 0, 0,
      "Disable compression of the build logs" },
    { "disable-store-optimization", GUIX_OPT_DISABLE_STORE_OPTIMIZATION, 0, 0,
      "Disable automatic file \"deduplication\" in the store" },
    { "impersonate-linux-2.6", GUIX_OPT_IMPERSONATE_LINUX_26, 0, 0,
      "Impersonate Linux 2.6"
#ifndef HAVE_SYS_PERSONALITY_H
      " (this option has no effect in this configuration)"
#endif
    },
    { "gc-keep-outputs", GUIX_OPT_GC_KEEP_OUTPUTS,
      "yes/no", OPTION_ARG_OPTIONAL,
      "Tell whether the GC must keep outputs of live derivations" },
    { "gc-keep-derivations", GUIX_OPT_GC_KEEP_DERIVATIONS,
      "yes/no", OPTION_ARG_OPTIONAL,
      "Tell whether the GC must keep derivations corresponding \
to live outputs" },

    { "listen", GUIX_OPT_LISTEN, "SOCKET", 0,
      "Listen for connections on SOCKET" },
    { "debug", GUIX_OPT_DEBUG, 0, 0,
      "Produce debugging output" },
    { 0, 0, 0, 0, 0 }
  };


/* Convert ARG to a Boolean value, or throw an error if it does not denote a
   Boolean.  */
static bool
string_to_bool (const char *arg, bool dflt = true)
{
  if (arg == NULL)
    return dflt;
  else if (strcasecmp (arg, "yes") == 0)
    return true;
  else if (strcasecmp (arg, "no") == 0)
    return false;
  else
    throw nix::Error (format ("'%1%': invalid Boolean value") % arg);
}

/* Parse a single option. */
static error_t
parse_opt (int key, char *arg, struct argp_state *state)
{
  switch (key)
    {
    case GUIX_OPT_DISABLE_CHROOT:
      settings.useChroot = false;
      break;
    case GUIX_OPT_CHROOT_DIR:
      settings.dirsInChroot.insert (arg);
      break;
    case GUIX_OPT_DISABLE_LOG_COMPRESSION:
      settings.compressLog = false;
      break;
    case GUIX_OPT_BUILD_USERS_GROUP:
      settings.buildUsersGroup = arg;
      break;
    case GUIX_OPT_DISABLE_STORE_OPTIMIZATION:
      settings.autoOptimiseStore = false;
      break;
    case GUIX_OPT_CACHE_FAILURES:
      settings.cacheFailure = true;
      break;
    case GUIX_OPT_IMPERSONATE_LINUX_26:
      settings.impersonateLinux26 = true;
      break;
    case GUIX_OPT_LOSE_LOGS:
      settings.keepLog = false;
      break;
    case GUIX_OPT_LISTEN:
      try
	{
	  settings.nixDaemonSocketFile = canonPath (arg);
	}
      catch (std::exception &e)
	{
	  fprintf (stderr, "error: %s\n", e.what ());
	  exit (EXIT_FAILURE);
	}
      break;
    case GUIX_OPT_NO_SUBSTITUTES:
      settings.set ("build-use-substitutes", "false");
      break;
    case GUIX_OPT_NO_BUILD_HOOK:
      settings.useBuildHook = false;
      break;
    case GUIX_OPT_DEBUG:
      verbosity = lvlDebug;
      break;
    case GUIX_OPT_GC_KEEP_OUTPUTS:
      settings.gcKeepOutputs = string_to_bool (arg);
      break;
    case GUIX_OPT_GC_KEEP_DERIVATIONS:
      settings.gcKeepDerivations = string_to_bool (arg);
      break;
    case 'c':
      settings.set ("build-cores", arg);
      break;
    case 'M':
      settings.set ("build-max-jobs", arg);
      break;
    case GUIX_OPT_SYSTEM:
      settings.thisSystem = arg;
      break;
    default:
      return (error_t) ARGP_ERR_UNKNOWN;
    }

  return (error_t) 0;
}

/* Argument parsing.  */
static struct argp argp = { options, parse_opt, 0, doc };



int
main (int argc, char *argv[])
{
  Strings nothing;

  /* Initialize libgcrypt.  */
  if (!gcry_check_version (GCRYPT_VERSION))
    {
      fprintf (stderr, "error: libgcrypt version mismatch\n");
      exit (EXIT_FAILURE);
    }

  /* Tell Libgcrypt that initialization has completed, as per the Libgcrypt
     1.6.0 manual (although this does not appear to be strictly needed.)  */
  gcry_control (GCRYCTL_INITIALIZATION_FINISHED, 0);

  /* Set the umask so that the daemon does not end up creating group-writable
     files, which would lead to "suspicious ownership or permission" errors.
     See <http://lists.gnu.org/archive/html/bug-guix/2013-07/msg00033.html>.  */
  umask (S_IWGRP | S_IWOTH);

#ifdef HAVE_CHROOT
  settings.useChroot = true;
#else
  settings.useChroot = false;
#endif

  argvSaved = argv;

  try
    {
      settings.processEnvironment ();

      /* Hackily help 'local-store.cc' find our 'guix-authenticate' program, which
	 is known as 'OPENSSL_PATH' here.  */
      std::string search_path (getenv ("PATH"));
      search_path = settings.nixLibexecDir + ":" + search_path;
      setenv ("PATH", search_path.c_str (), 1);

      /* Use our substituter by default.  */
      settings.substituters.clear ();
      settings.set ("build-use-substitutes", "true");

#ifdef HAVE_DAEMON_OFFLOAD_HOOK
      /* Use our build hook for distributed builds by default.  */
      settings.useBuildHook = true;
      if (getenv ("NIX_BUILD_HOOK") == NULL)
	{
	  std::string build_hook;

	  build_hook = settings.nixLibexecDir + "/guix/offload";
	  setenv ("NIX_BUILD_HOOK", build_hook.c_str (), 1);
	}
#else
      /* We are not installing any build hook, so disable it.  */
      settings.useBuildHook = false;
#endif

      argp_parse (&argp, argc, argv, 0, 0, 0);

      /* Effect all the changes made via 'settings.set'.  */
      settings.update ();

      if (settings.useSubstitutes)
	{
	  string subs = getEnv ("NIX_SUBSTITUTERS", "default");

	  if (subs == "default")
	    {
	      string subst =
		settings.nixLibexecDir + "/guix/substitute-binary";
	      setenv ("NIX_SUBSTITUTERS", subst.c_str (), 1);
	    }
	}
      else
	/* Clear the substituter list to make sure nothing ever gets
	   substituted, regardless of the client's settings.  */
	setenv ("NIX_SUBSTITUTERS", "", 1);

      /* Effect the $NIX_SUBSTITUTERS change.  */
      settings.update ();

      if (geteuid () == 0 && settings.buildUsersGroup.empty ())
	fprintf (stderr, "warning: daemon is running as root, so "
		 "using `--build-users-group' is highly recommended\n");

#ifdef HAVE_CHROOT
      if (settings.useChroot)
	{
	  foreach (PathSet::iterator, i, settings.dirsInChroot)
	    {
	      printMsg (lvlDebug,
			format ("directory `%1%' added to the chroot") % *i);
	    }
	}
#endif

      printMsg (lvlDebug,
		format ("listening on `%1%'") % settings.nixDaemonSocketFile);

      run (nothing);
    }
  catch (std::exception &e)
    {
      fprintf (stderr, "error: %s\n", e.what ());
      return EXIT_FAILURE;
    }

  return EXIT_SUCCESS;				  /* never reached */
}
