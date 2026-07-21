# Native Samba 4.10.18 build for legacy Raspberry Pi OS

This directory documents a native build of Samba 4.10.18 produced on the original WDPi hardware.

The build was compiled directly on a physical Raspberry Pi Compute Module 3 Rev 1.0 running Raspbian GNU/Linux 8 (Jessie). No cross-compilation, emulation, container, virtual machine or chroot was used.

## Build profile

- Samba 4.10.18
- 32-bit ARM EABI5 hard-float
- ARMv6 instruction baseline with VFPv2
- build host: Raspberry Pi Compute Module 3 Rev 1.0
- build OS: Raspbian GNU/Linux 8 Jessie
- compiler: GCC 4.9.2
- binutils: 2.25
- Python used by Waf: 2.7.9
- installation prefix: `/opt/samba-4.10.18`
- runtime tree size before compression: approximately 43 MiB

## Configure profile

```text
PYTHON=python2 ./configure \
  --prefix=/opt/samba-4.10.18 \
  --without-ad-dc \
  --disable-python \
  --disable-cups \
  --without-json \
  --without-ldap \
  --without-ads
```

The build includes a standalone Samba file server, `smbclient`, administrative utilities, POSIX ACL support, PAM, libarchive, FUSE, Winbind components, quota support and Samba's bundled Heimdal components. Active Directory Domain Controller support, ADS/domain-member integration, LDAP, Python runtime modules, CUPS and JSON/Jansson-dependent functionality were excluded.

GnuTLS development support was unavailable on the build host. The selected standalone file-server configuration completed successfully without it; GnuTLS-dependent functionality is therefore not included.

## Recorded timings

- configure: 10m 10.151s
- build: 1h 17m 40.253s
- measured build wall time: 1h 17m 46.320s
- staged installation: 12m 1.496s
- total recorded configure, build and staging time: approximately 1h 40m

## Validation

The resulting binaries were installed under `/opt/samba-4.10.18` alongside, rather than over, the system Samba 4.2 installation.

Initial isolated validation included:

- `smbd`, `smbclient` and `testparm` reporting version 4.10.18;
- complete dynamic dependency resolution on the build host;
- an isolated `smbd` instance listening on `127.0.0.1:1445`;
- successful anonymous SMB directory listing;
- successful SMB file upload;
- clean shutdown of the isolated test server.

The build was subsequently deployed as the production Samba implementation. Native systemd units start `/opt/samba-4.10.18/sbin/smbd` and `/opt/samba-4.10.18/sbin/nmbd`, both using the existing `/etc/samba/smb.conf`. The packaged Samba 4.2 files remain installed for rollback and dependency compatibility, but do not provide the active SMB or NetBIOS daemons.

Post-reboot production validation confirmed:

- both `smbd.service` and `nmbd.service` active and enabled;
- every active Samba daemon resolving to `/opt/samba-4.10.18` and reporting version 4.10.18;
- `smbd` listening on TCP 139 and 445;
- `nmbd` listening on UDP 137 and 138;
- successful authenticated access to the production share and directory listing after reboot;
- correct startup after the `/ftp` data mount became available.

Sanitized service definitions are stored under `config/systemd/`.

## Distribution artifacts

The corresponding GitHub release contains:

- `samba-4.10.18-rpi-armhf-runtime.tar.xz` — the validated `/opt/samba-4.10.18` runtime tree;
- `samba-4.10.18.tar.gz` — the exact upstream source archive used for the build;
- `SHA256SUMS` — checksums for the published archives.

Published SHA-256 checksums:

```text
0605b291968a2591c5dcdc50aa7b92c20df9b8190f63bd19b7b286984c224837  samba-4.10.18-rpi-armhf-runtime.tar.xz
7dcfc2aaaac565b959068788e6a43fc79ce2a03e7d523f5843f7a9fddffc7c2c  samba-4.10.18.tar.gz
```

## Compatibility

Tested:

- Raspberry Pi Compute Module 3
- Raspbian GNU/Linux 8 Jessie
- ARM hard-float userspace

Potential but not tested:

- Raspberry Pi 1 and Raspberry Pi Zero systems using a compatible ARMv6 hard-float userspace and sufficiently compatible runtime libraries

The ARMv6 ELF baseline does not by itself guarantee compatibility with every ARMv6 distribution.

## Documentation

- [`FEATURE-MATRIX.md`](FEATURE-MATRIX.md)
- [`BUILD-PROVENANCE.txt`](BUILD-PROVENANCE.txt)
- [`BUILD-HOST.txt`](BUILD-HOST.txt)
- [`ELF-ABI.txt`](ELF-ABI.txt)
- [`SOURCE-SHA256.txt`](SOURCE-SHA256.txt)
- [`../docs/maintenance-2026-07-21.md`](../docs/maintenance-2026-07-21.md)

## Security and maintenance status

Samba 4.10.18 and Raspbian Jessie are obsolete. This build is retained as a historical and compatibility artifact for legacy hardware. It should not be treated as a current secure-by-default Samba distribution or exposed to an untrusted network without an independent security review and appropriate network controls.
