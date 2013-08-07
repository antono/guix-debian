/* GNU Guix --- Functional package management for GNU
   Copyright (C) 2012  Ludovic Courtès <ludo@gnu.org>

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

#include <gcrypt-hash.hh>

#define SHA_CTX guix_hash_context

static inline void
SHA1_Init (struct SHA_CTX *ctx)
{
  guix_hash_init (ctx, GCRY_MD_SHA1);
}

#define SHA1_Update guix_hash_update

static inline void
SHA1_Final (void *resbuf, struct SHA_CTX *ctx)
{
  guix_hash_final (resbuf, ctx, GCRY_MD_SHA1);
}
