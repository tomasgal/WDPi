# WDPi

Western Digital / Raspberry Pi Compute Module based mini NAS.

WDPi began as a small, low-power NAS build based on a Raspberry Pi Compute Module 3 and a Western Digital SATA adapter board. The original setup provided Samba file sharing on the local network and a lightweight read-only directory view through MiniHTTPD.

The same device has remained in continuous use since the original deployment, although its services and storage layout have evolved over time. This repository therefore serves two related purposes:

- it preserves the original hardware build and boot-time configuration;
- it documents the server's later use as a Samba and FTP storage appliance.

In July 2026, a dedicated scan-to-FTP destination was added for a network multifunction printer. This scanner integration is a new function layered onto the continuously used server, not part of the original WDPi build.

This is a historical build log and a sanitized configuration snapshot, not a maintained NAS distribution or a secure-by-default deployment image.

## Original project

The original topology was:

```text
2.5" SATA disk
    -> Western Digital SATA adapter board
    -> Raspberry Pi Compute Module 3
    -> local network
    -> Samba share and MiniHTTPD directory view
```

The USB Wi-Fi adapter was an important part of the build. At the time, Raspberry Pi Linux did not work reliably with every USB Wi-Fi device, especially among faster adapters, so documenting a working adapter had practical value for other hobbyists.

### Original hardware

- Western Digital [2.5-inch SATA to Raspberry Pi Adapter](http://wdlabs.wd.com/products/sata-adapter-board/)
- Raspberry Pi Foundation [Compute Module 3](https://www.raspberrypi.org/blog/raspberry-pi-compute-module-new-product/)
- Edimax ED600 USB Wi-Fi adapter
- Seagate SSHD 1 TB

### Original software and services

- Raspbian
- Samba for LAN file sharing
- MiniHTTPD for a lightweight web view
- `tree` for generating a static HTML directory listing at boot
- `hdparm` for HDD power-management settings

## Historical boot-time behavior

The included [`rc.local`](rc.local) file records the original workflow:

1. print the current IP address;
2. mount the attached storage device at `/nas`;
3. bind-mount `/nas` into MiniHTTPD's web root;
4. apply HDD standby and power-management settings with `hdparm`;
5. generate a static HTML directory tree with `tree`;
6. start MiniHTTPD after a short delay.

The generated directory snapshot was written to:

```text
/nas/tree.html
```

This was a boot-time snapshot rather than a recurring cron task. The historical [`mini-httpd.conf`](mini-httpd.conf) is retained as an anonymized example.

## Current deployment (2026)

After years of continuous use, the original device now operates primarily as a small Samba and FTP storage server. Its current logical layout includes:

- Samba file sharing for authenticated users on the local network;
- vsftpd access with separate authenticated and anonymous policies;
- two personal areas, each writable by its owner and readable by the other authenticated user;
- a common `share` area that authenticated users can modify and anonymous FTP users can only read;
- an anonymous read/write `upload` area stored on a separate USB flash drive;
- an isolated FTP account and directory, added in July 2026, for a Pantum multifunction printer's scan-to-FTP function;
- read-only access for the human users to files created by the printer;
- POSIX ACLs and default ACLs implementing the directory-level access model;
- UUID-based mounts in `/etc/fstab`;
- a systemd dependency preventing vsftpd from starting before both data filesystems are mounted.

For the printer account, FTP path `/` maps directly to its private physical directory. The printer cannot see the shared, upload or personal areas. The server-side login and upload path have been tested; an actual scan initiated at the printer remains an on-site acceptance test.

The public repository intentionally excludes passwords, password hashes, public hostnames, routable addresses, real filesystem UUIDs and private filenames.

Detailed current documentation is available in:

- [`docs/current-deployment.md`](docs/current-deployment.md) — storage topology, services and access model;
- [`docs/maintenance-2026-07-15.md`](docs/maintenance-2026-07-15.md) — consolidated maintenance and validation record;
- [`config/`](config/) — sanitized examples of the active Samba, vsftpd, PAM, ACL, mount and systemd configuration.

## Repository layout

```text
README.md                         Historical and current project overview
rc.local                         Historical boot workflow
mini-httpd.conf                  Historical MiniHTTPD example
config/                          Sanitized current configuration examples
docs/current-deployment.md       Current topology and access model
docs/maintenance-2026-07-15.md   Consolidated maintenance record
```

## Images

WDPi project image:

![WDPi project image](wdpi.gif)

WDPi picture of later version:

![WDPi later version](wdpi_rev1.jpg)

## Current limitations

- The operating system and many packages reflect the original deployment era and are obsolete.
- The current FTP configuration uses unencrypted FTP for compatibility with legacy and embedded clients.
- Anonymous write access is intentionally restricted to one ACL-controlled upload filesystem.
- The repository configurations are sanitized examples and must be reviewed before use on another system.
- This setup should not be exposed to an untrusted network without current packages, restricted network access, firewalling, logging, transport security and a fresh security review.

## Authorship and media rights

Project documentation and photographs by Tomáš Gál, unless otherwise noted.

External project links and product names are included for hardware identification and historical context.
