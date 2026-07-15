# Current WDPi deployment

This document describes the sanitized logical configuration observed and repaired in July 2026. It intentionally omits credentials, public hostnames, routable addresses, real filesystem UUIDs, and private filenames.

The server was not revived from an abandoned state for this work. It had remained in continuous practical use since the original NAS deployment, while its role and configuration evolved over time. The July 2026 maintenance consolidated the existing Samba and FTP setup and added a new isolated scan-to-FTP destination for a multifunction printer.

## Platform

- Raspberry Pi Compute Module 3 era hardware
- Raspbian GNU/Linux 8 (Jessie-era installation)
- Linux 4.9 series kernel
- primary data storage presented as a WD My Book device
- separate Kingston DataTraveler USB 2.0 flash drive used for anonymous FTP uploads
- operating system stored on the Compute Module's MMC device

The platform is still functional, but the operating system is obsolete. This documentation records the current arrangement; it does not imply that the stack is suitable for a new deployment.

## Storage topology

```text
MMC system storage
├── /          operating system
└── /boot      boot filesystem

WD data filesystem
└── /ftp
    ├── primary-user/
    ├── secondary-user/
    ├── share/
    ├── scanner/
    └── upload/       nested mount point

Kingston USB filesystem
└── /ftp/upload
```

The data filesystems are mounted by UUID through `/etc/fstab`. The nested mount order matters: `/ftp` must exist before `/ftp/upload` is mounted.

Both data entries use `nofail`, so failure of removable or external storage does not prevent the base system and SSH from booting. A systemd override adds `RequiresMountsFor=/ftp /ftp/upload` to vsftpd, preventing FTP from starting against empty mount-point directories on the system filesystem.

See:

- `config/fstab.data.example`
- `config/systemd/vsftpd.service.d/mounts.conf`

## Network services

### Samba

Samba exposes `/ftp` as one authenticated share. Access inside the tree is controlled by Unix ownership and POSIX ACLs rather than by separate Samba shares for every directory.

The sanitized share definition is in `config/samba-share.conf.example`.

### FTP

vsftpd provides two classes of access:

1. authenticated local accounts;
2. anonymous FTP mapped to the dedicated Unix account used by vsftpd.

The service uses a positive user allowlist. The global local root is `/ftp`; a per-user configuration overrides the scanner account's root so that it sees only its private directory.

The installation currently uses plain FTP for compatibility with embedded and legacy clients. TLS is not enabled in the documented active configuration.

## Access model

`R` means list/read/traverse. `RW` means create, modify, rename and delete where supported by the FTP or Samba client.

| Area | Primary user | Secondary user | Anonymous FTP | Scanner account |
|---|---:|---:|---:|---:|
| Primary personal area | RW | R | none | none |
| Secondary personal area | R | RW | none | none |
| `share` | RW | RW | R | none |
| `upload` | RW | RW | RW | none |
| `scanner` | R | R | none | RW |

The scanner account is chrooted directly into its own directory. For that account, FTP path `/` maps to the physical directory `/ftp/scanner`; it cannot see `/ftp`, `share`, `upload`, or either personal area.

## ACL strategy

The access model relies on POSIX ACLs rather than world-readable or world-writable permissions.

Important consequences:

- the anonymous Unix account has read-only ACL entries in `share`;
- the same account owns or has read/write ACL access in `upload`;
- the two authenticated users have reciprocal read-only ACL access to personal directories;
- both authenticated users have read/write access in `share` and `upload`;
- the scanner owns its directory, while the two authenticated users receive read-only ACL entries;
- `other::---` is used on controlled directories;
- default ACLs are used so that newly created files inherit the intended policy.

Because anonymous files are intentionally readable through an ACL rather than the traditional `other` permission bits, vsftpd must use:

```ini
anon_world_readable_only=NO
```

Without that setting, anonymous login and directory traversal may succeed while directory listings appear empty or end with `Transfer done (but failed to open directory)`.

A non-destructive example for a fresh directory layout is provided in `config/acl-layout.example.sh`. Review all variables and paths before running it.

## Anonymous FTP policy

Anonymous FTP is intentionally asymmetric:

- `share` can be listed and downloaded but not modified;
- `upload` can be listed, uploaded to, renamed and deleted;
- personal and scanner directories cannot be entered;
- `lost+found` directories are hidden from listings and denied by name.

The relevant vsftpd directives are:

```ini
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
anon_world_readable_only=NO
hide_file={lost+found}
deny_file={lost+found}
```

The broad anonymous FTP operation switches are constrained by filesystem ACLs. They do not by themselves grant write access to `share` or the personal areas.

## Scanner / multifunction printer integration

The isolated FTP account was added in July 2026 as a new function of the continuously used server. It is intended for a network multifunction printer's FTP address-book or scan-to-FTP feature.

A typical printer entry uses:

```text
Service name:      WDPi
Protocol:          FTP
Server:            <LAN-IP-OR-HOSTNAME>
Port:              21
Username:          <SCANNER_USER>
Password:          <SCANNER_PASSWORD>
FTP subdirectory:  /
Passive mode:      enabled, if configurable
TLS/SSL:           disabled for the current compatibility setup
```

The service name is only a label stored by the printer. The subdirectory `/` is correct because the account's FTP root is already mapped to its private physical directory.

Server-side login, listing and upload were tested successfully. A physical scan from the printer remains a separate on-site acceptance test.

## Configuration files

The repository includes sanitized examples for:

- vsftpd global configuration;
- the positive FTP user allowlist;
- the scanner account's per-user vsftpd configuration;
- the FTP welcome banner;
- the PAM policy used by vsftpd;
- the Samba share;
- the two data mounts in `/etc/fstab`;
- the systemd mount dependency;
- the intended ACL layout.

Placeholders must be replaced locally. Do not commit real passwords, password hashes, public DNS names, IP addresses, or filesystem UUIDs.

## Verified behavior

The following paths were tested through the FTP protocol, not only with local `ls` or `test` commands:

- anonymous login succeeds;
- anonymous listing and download from `share` succeeds;
- anonymous upload into `share` fails;
- anonymous upload, listing and deletion in `upload` succeeds;
- anonymous entry into personal directories fails;
- authenticated login succeeds;
- an authenticated user can write to the user's own personal area;
- the same user can read but not write to the other personal area;
- authenticated write into `share` succeeds;
- newly created content in `share` is readable anonymously;
- the scanner account logs in, sees an empty `/`, and can upload there;
- a normal authenticated user can read the scanner-created test file;
- vsftpd remains active after adding the mount dependency.

## Remaining operational checks

- perform a cold reboot and confirm that `/ftp`, `/ftp/upload`, and vsftpd all become active in the intended order;
- perform an actual scan-to-FTP operation from the multifunction printer;
- verify the second authenticated FTP account end-to-end after any future password or ACL changes;
- plan migration from the obsolete operating-system release;
- consider TLS, VPN-only exposure, or another encrypted transfer path where client compatibility permits it.
