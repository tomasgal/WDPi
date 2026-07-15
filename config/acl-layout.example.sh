#!/bin/sh
set -eu

# EXAMPLE ONLY. Review paths and account names before running.
# Intended for a fresh directory tree, not for blind use on existing data.

ROOT=/ftp
PRIMARY_USER=primary-user
SECONDARY_USER=secondary-user
ANON_USER=ftp
SCANNER_USER=scanner

install -d -m 2750 "$ROOT/$PRIMARY_USER" "$ROOT/$SECONDARY_USER"
install -d -m 2770 "$ROOT/share" "$ROOT/upload"
install -d -o "$SCANNER_USER" -g "$SCANNER_USER" -m 0700 "$ROOT/scanner"

# Personal areas: owner RW, the other authenticated user R.
setfacl -m "u:$SECONDARY_USER:r-x,g::---,o::---" "$ROOT/$PRIMARY_USER"
setfacl -m "u:$PRIMARY_USER:r-x,g::---,o::---" "$ROOT/$SECONDARY_USER"

# Shared area: authenticated users RW, anonymous account R.
setfacl -m "u:$ANON_USER:r-x,g:users:rwx,g::---,m::rwx,o::---" "$ROOT/share"
setfacl -d -m "u::rwx,u:$ANON_USER:r-x,g:users:rwx,g::---,m::rwx,o::---" "$ROOT/share"

# Upload area: anonymous and both authenticated users RW.
setfacl -m "u:$ANON_USER:rwx,u:$PRIMARY_USER:rwx,u:$SECONDARY_USER:rwx,g::---,m::rwx,o::---" "$ROOT/upload"
setfacl -d -m "u::rwx,u:$ANON_USER:rwx,u:$PRIMARY_USER:rwx,u:$SECONDARY_USER:rwx,g::---,m::rwx,o::---" "$ROOT/upload"

# Scanner area: scanner RW, authenticated users R, everyone else none.
setfacl -m "u:$PRIMARY_USER:r-x,u:$SECONDARY_USER:r-x,g::---,m::rwx,o::---" "$ROOT/scanner"
setfacl -d -m "u::rwx,u:$PRIMARY_USER:r-x,u:$SECONDARY_USER:r-x,g::---,m::rwx,o::---" "$ROOT/scanner"

printf '%s\n' 'ACL example applied. Verify every effective permission before enabling services.'
