# WDPi

Western Digital / Raspberry Pi Compute Module based mini NAS.

WDPi is a small, low-power storage server based on a Raspberry Pi Compute Module 3 and a Western Digital storage adapter. The repository began as a build log for a simple Samba and MiniHTTPD NAS. The original device remains operational, but its present-day role has expanded to include controlled FTP access and a dedicated scan-to-FTP drop location.

## Project status

This repository is a historical hardware build log and a sanitized configuration snapshot of a still-running personal server. It is not a maintained NAS distribution or a secure-by-default deployment image.

The installed operating system and much of the software reflect the original deployment era. The example configurations document the current logical arrangement, but they must be reviewed before use on another host.

## Current use

The current deployment provides:

- Samba file sharing for authenticated users on the local network;
- vsftpd access with separate authenticated and anonymous policies;
- a read-only shared FTP area;
- an anonymous read/write upload area on a separate USB flash drive;
- two personal areas with owner read/write and reciprocal read-only access;
- an isolated FTP account and directory intended for a multifunction printer's scan-to-FTP feature;
- UUID-based data mounts managed through `/etc/fstab`;
- a systemd dependency that prevents vsftpd from starting before both data filesystems are mounted.

No passwords, password hashes, public hostnames, routable addresses, real filesystem UUIDs, or private data are included in this repository.

See:

- [`docs/current-deployment.md`](docs/current-deployment.md) for the current topology and access model;
- [`docs/maintenance-2026-07-15.md`](docs/maintenance-2026-07-15.md) for the consolidated maintenance record;
- [`config/`](config/) for sanitized configuration examples.

## Historical overview

The original topology was:

```text
2.5" SATA disk
    -> Western Digital storage adapter
    -> Raspberry Pi Compute Module 3
    -> local network
    -> Samba share and MiniHTTPD directory view
```

The USB Wi-Fi adapter was an important part of the build. At the time, Raspberry Pi Linux did not work reliably with every USB Wi-Fi device, especially among faster adapters, so documenting a working adapter had practical value for other hobbyists.

## Hardware

- Western Digital 2.5-inch storage adapter board;
- Raspberry Pi Foundation Compute Module 3;
- Edimax USB Wi-Fi adapter;
- internal hard disk used as the primary data volume;
- Kingston USB 2.0 flash drive used as the separate FTP upload volume.

The current kernel identifies the main external storage enclosure as a WD My Book device and the upload medium as a Kingston DataTraveler. Device names such as `/dev/sda` and `/dev/sdb` are observational only; persistent mounts use filesystem UUIDs.

## Software

### Current operational services

- Raspbian GNU/Linux 8 (Jessie-era installation);
- Samba for authenticated LAN file sharing;
- vsftpd for authenticated and anonymous FTP;
- POSIX ACLs for directory-level access control;
- systemd-generated mount units based on `/etc/fstab`.

### Historical components retained in the repository

- MiniHTTPD for a lightweight web view;
- `tree` for generating a static HTML directory listing;
- `hdparm` for disk power-management settings;
- `rc.local` as documentation of the original boot workflow.

The current configuration documentation focuses on Samba and FTP. The historical `rc.local` and `mini-httpd.conf` files are retained as artifacts of the original deployment.

## Repository layout

```text
README.md                         Project overview
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

## Security limitations

- The operating system release is obsolete and no longer receives normal security support.
- The documented FTP service currently uses unencrypted FTP for compatibility with legacy clients and embedded devices.
- Anonymous write access is intentionally limited to one ACL-controlled upload filesystem.
- These examples must not be copied to an internet-facing host without current packages, firewalling, restricted exposure, logging, transport security, and a fresh security review.
- The repository contains no credentials. Accounts and UUIDs in examples are placeholders.

## Authorship and media rights

Project documentation and photographs by Tomáš Gál, unless otherwise noted.

External project links and product names are included only for hardware identification and historical context.
