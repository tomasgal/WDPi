# Current WDPi deployment

This document describes the sanitized logical configuration observed and repaired in July 2026. It intentionally omits credentials, public hostnames, routable addresses, real filesystem UUIDs, and private filenames.

The server was not revived from an abandoned state for this work. It had remained in continuous practical use since the original NAS deployment, while its role and configuration evolved over time. The July 2026 maintenance consolidated the existing Samba and FTP setup, added a new isolated scan-to-FTP destination for a multifunction printer, restored a live read-only MiniHTTPD view of the current storage tree, and replaced the active packaged Samba 4.2 daemons with a native Samba 4.10.18 build.

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

Both data entries use `nofail`, so failure of removable or external storage does not prevent the base system and SSH from booting. A systemd override adds `RequiresMountsFor=/ftp /ftp/upload` to vsftpd, preventing FTP from starting against empty mount-point directories on the system filesystem. Separate overrides require `/ftp` before Samba and MiniHTTPD start, because their share root, web root, and application logs are located on the data filesystem.

See:

- `config/fstab.data.example`
- `config/systemd/vsftpd.service.d/mounts.conf`
- `config/systemd/smbd.service.example`
- `config/systemd/nmbd.service.example`

## Network configuration

The Wi-Fi interface is associated and authenticated by `wpa_supplicant`, while IPv4 configuration is obtained by `dhclient` under `networking.service`.

A second DHCP manager, `dhcpcd`, had also been enabled. Its logs showed that it had previously removed the active IPv4 address, connected route, and default route from the Wi-Fi interface while `dhclient` was managing the same lease. This duplicate network-management path was disabled and masked. Post-reboot validation confirmed that:

- `wpa_supplicant` starts normally;
- one `dhclient` process manages the Wi-Fi interface;
- `dhcpcd` remains masked and does not run;
- the expected IPv4 address, connected route, and default route are restored at boot;
- SSH and authenticated SMB access are available after startup.

`dhcpcd` was not a Wi-Fi driver. The USB Wi-Fi device remains controlled by the kernel driver, with `wpa_supplicant` providing wireless association and `dhclient` providing DHCP configuration.

## Network services

### Samba

Samba exposes `/ftp` as one authenticated share. Access inside the tree is controlled by Unix ownership and POSIX ACLs rather than by separate Samba shares for every directory.

The active production daemons are Samba 4.10.18 binaries installed under `/opt/samba-4.10.18`. The packaged Samba 4.2 installation remains present, but its daemon binaries are not used by the active services.

Two native systemd units start:

```text
/opt/samba-4.10.18/sbin/smbd
/opt/samba-4.10.18/sbin/nmbd
```

Both services use the single shared configuration file:

```text
/etc/samba/smb.conf
```

The service units run the daemons in the foreground with `--no-process-group`, provide the required runtime, state, cache, private and PID directories, and depend on `/ftp` through `RequiresMountsFor=/ftp`.

Post-reboot validation confirmed:

- `smbd.service` and `nmbd.service` are active and enabled;
- all active Samba processes resolve to `/opt/samba-4.10.18` and report version 4.10.18;
- `smbd` listens on TCP 139 and 445;
- `nmbd` listens on UDP 137 and 138;
- authenticated access to the production share succeeds;
- directory listing succeeds after reboot.

Multiple `smbd` processes are expected: Samba uses a parent daemon and helper or per-client processes. They do not indicate duplicate Samba installations.

The sanitized share definition is in `config/samba-share.conf.example`. Sanitized production service units are in `config/systemd/smbd.service.example` and `config/systemd/nmbd.service.example`.

### FTP

vsftpd provides two classes of access:

1. authenticated local accounts;
2. anonymous FTP mapped to the dedicated Unix account used by vsftpd.

The service uses a positive user allowlist. The global local root is `/ftp`; a per-user configuration overrides the scanner account's root so that it sees only its private directory.

The installation currently uses plain FTP for compatibility with embedded and legacy clients. TLS is not enabled in the documented active configuration.

### Read-only web directory view

MiniHTTPD binds to a local-network address and serves `/ftp` as a live directory tree. It provides browser-based read and download access only; it is not a web file manager and does not provide upload, rename, or delete operations.

The MiniHTTPD service account receives read and traversal access through POSIX ACLs. Filesystem recovery directories such as `lost+found` remain inaccessible. The view otherwise covers the server-wide storage tree, including personal areas, `share`, `upload`, the scanner directory, and operational files intentionally stored below `/ftp`.

This web view is deliberately broader than the isolated FTP view presented to the scanner account. The scanner's FTP login is chrooted into one private directory, while MiniHTTPD presents a single server-wide read-only view. Access control for the web service is therefore primarily network-level: it is intended only for a trusted LAN and must not be exposed as a public web interface.

## Access model

`R` means list/read/traverse. `RW` means create, modify, rename and delete where supported by the FTP or Samba client.

| Area | Primary user | Secondary user | Anonymous FTP | Scanner account | MiniHTTPD LAN view |
|---|---:|---:|---:|---:|---:|
| Primary personal area | RW | R | none | none | R |
| Secondary personal area | R | RW | none | none | R |
| `share` | RW | RW | R | none | R |
| `upload` | RW | RW | RW | none | R |
| `scanner` | R | R | none | RW | R |

The scanner account is chrooted directly into its own directory. For that account, FTP path `/` maps to the physical directory `/ftp/scanner`; it cannot see `/ftp`, `share`, `upload`, or either personal area.

MiniHTTPD does not impersonate any FTP account. Its separate service account has read-only ACL access to the directories shown above, so the web view does not reproduce the per-account FTP isolation model.

## ACL strategy

The access model relies on POSIX ACLs rather than world-readable or world-writable permissions.

Important consequences:

- the anonymous Unix account has read-only ACL entries in `share`;
- the same account owns or has read/write ACL access in `upload`;
- the two authenticated users have reciprocal read-only ACL access to personal directories;
- both authenticated users have read/write access in `share` and `upload`;
- the scanner owns its directory, while the two authenticated users receive read-only ACL entries;
- the MiniHTTPD service account receives read and traversal access without write access;
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

Files stored in the scanner directory are also available through the MiniHTTPD directory tree as read-only web content on the local network. This gives users a simple browser-based way to retrieve printer uploads without granting the printer access to the rest of the FTP hierarchy.

Server-side login, listing and upload were tested successfully. A physical scan from the printer remains a separate on-site acceptance test.

## Configuration files

The repository includes sanitized examples for:

- vsftpd global configuration;
- the positive FTP user allowlist;
- the scanner account's per-user vsftpd configuration;
- the FTP welcome banner;
- the PAM policy used by vsftpd;
- the Samba share;
- the production Samba systemd units;
- the two data mounts in `/etc/fstab`;
- the service mount dependencies;
- the intended ACL layout.

Placeholders must be replaced locally. Do not commit real passwords, password hashes, public DNS names, IP addresses, or filesystem UUIDs.

## Verified behavior

The following paths were tested through the relevant network protocols, not only with local `ls` or `test` commands:

- anonymous FTP login succeeds;
- anonymous listing and download from `share` succeeds;
- anonymous upload into `share` fails;
- anonymous upload, listing and deletion in `upload` succeeds;
- anonymous entry into personal directories fails;
- authenticated FTP login succeeds;
- an authenticated user can write to the user's own personal area;
- the same user can read but not write to the other personal area;
- authenticated write into `share` succeeds;
- newly created content in `share` is readable anonymously;
- the scanner account logs in, sees an empty `/`, and can upload there;
- a normal authenticated user can read the scanner-created test file;
- the MiniHTTPD root responds successfully over HTTP on the local network;
- MiniHTTPD presents the `/ftp` tree and provides read-only access to the scanner storage directory;
- MiniHTTPD continues writing to its active log after log rotation using `copytruncate`;
- vsftpd remains active after adding the mount dependency;
- a full reboot restores the expected data mounts, network configuration and production Samba services;
- Samba 4.10.18 provides authenticated SMB access after reboot;
- the duplicate `dhcpcd` network manager remains disabled and masked after reboot.

## Remaining operational checks

- perform an actual scan-to-FTP operation from the multifunction printer;
- verify the second authenticated FTP account end-to-end after any future password or ACL changes;
- plan migration from the obsolete operating-system release;
- consider TLS, VPN-only exposure, or another encrypted transfer path where client compatibility permits it;
- keep MiniHTTPD bound to a trusted local network and do not expose its server-wide directory view publicly.
