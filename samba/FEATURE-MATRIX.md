# Samba 4.10.18 Build Feature Matrix

## Build profile

- Standalone Samba file-server and client build
- Native ARM build for Linux
- Install prefix: `/opt/samba-4.10.18`
- 32-bit ARM EABI5 hard-float
- ARMv6 instruction baseline, VFPv2
- Built on Raspberry Pi Compute Module 3 Rev 1.0
- Raspbian GNU/Linux 8 (Jessie)

## Included and enabled

- `smbd`
- `smbclient`
- `testparm`
- `smbpasswd`
- `pdbedit`
- `smbcontrol`
- Local `tdbsam` and `smbpasswd` authentication backends
- Unix authentication
- POSIX ACL support
- Extended attributes
- PAM and PAM modules
- libarchive support
- FUSE support
- Kerberos and GSSAPI support using Samba's Heimdal components
- Winbind components
- Quota support
- IPv6
- Linux inotify
- Linux sendfile
- asynchronous I/O support
- large-file support with 64-bit `off_t`
- syslog
- pthread pool
- DNS update components
- automount support

## Explicitly disabled at configure time

- Active Directory Domain Controller (`--without-ad-dc`)
- ADS/domain-member integration (`--without-ads`)
- LDAP integration (`--without-ldap`)
- Python runtime modules (`--disable-python`)
- CUPS printing integration (`--disable-cups`)
- JSON/Jansson-dependent functionality (`--without-json`)

## Unavailable on the build host

- GnuTLS development headers and corresponding GnuTLS feature support

The selected standalone file-server configuration completed successfully without GnuTLS.
GnuTLS-dependent functionality is therefore not included in this build.

## Cluster support

- None

## External runtime dependencies on the build host

The runtime uses standard Raspbian Jessie libraries, including:

- glibc
- libacl
- libattr
- libpam
- libaudit
- zlib
- libcrypt
- libpthread
- libdl
- libresolv
- libnsl
- libutil

Samba-specific libraries are supplied under:

- `/opt/samba-4.10.18/lib`
- `/opt/samba-4.10.18/lib/private`

A complete per-ELF dependency listing was generated during validation.
No unresolved ELF dependency was found on the build host.

## Validation performed

- `smbd`, `smbclient`, and `testparm` reported version 4.10.18.
- An isolated `smbd` instance listened successfully on `127.0.0.1:1445`.
- Anonymous share connection and directory listing succeeded.
- SMB file upload succeeded.
- The test did not replace or interrupt the system Samba 4.2 installation.

## Compatibility status

Tested:

- Raspberry Pi Compute Module 3
- Raspbian GNU/Linux 8 Jessie
- ARM hard-float userspace

Potential but not tested:

- Raspberry Pi 1 and Raspberry Pi Zero systems with a compatible ARMv6
  hard-float userspace and sufficiently compatible runtime libraries

The ARMv6 ELF baseline alone does not guarantee compatibility with every ARMv6
distribution.
