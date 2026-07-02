# WDPi

Western Digital / Raspberry Pi Compute Module based mini NAS.

WDPi is a small, low-power NAS build based on a Raspberry Pi Compute Module 3 and a Western Digital SATA adapter board. It provides basic file sharing on a local network through Samba and a lightweight read-only web view through MiniHTTPD.

The device is still functional in the sense that the original hardware is connected to a local network and performs its intended role. The project is not actively maintained as a current software distribution: the operating system, system libraries, and installed applications reflect the original deployment era and are not kept up to date here.

## Project status

This repository is best understood as a historical hardware build log and configuration snapshot. It is not a ready-made NAS distribution and should not be deployed on an untrusted network without modernization.

The repository may still be useful for hobbyists interested in:

- Raspberry Pi Compute Module based storage builds,
- the historical Western Digital SATA adapter board,
- low-power local NAS experiments,
- USB Wi-Fi compatibility notes from the Raspberry Pi Linux ecosystem of that period,
- simple Samba and MiniHTTPD based file access.

## Overview

The basic topology is:

```text
2.5" SATA disk
    -> Western Digital SATA adapter board
    -> Raspberry Pi Compute Module 3
    -> local network
    -> Samba share and MiniHTTPD directory view
```

The USB Wi-Fi adapter was an important part of the build. At the time, Raspberry Pi Linux did not work reliably with every USB Wi-Fi device, especially among faster adapters, so documenting a working adapter had practical value for other hobbyists.

## Hardware

- Western Digital [2.5” SATA to Raspberry Pi Adapter](http://wdlabs.wd.com/products/sata-adapter-board/)
- Raspberry Pi Foundation [Compute Module 3](https://www.raspberrypi.org/blog/raspberry-pi-compute-module-new-product/)
- Edimax ED600 USB Wi-Fi adapter
- Seagate SSHD 1 TB

## Software

- Raspbian
- Samba for LAN file sharing
- MiniHTTPD for a lightweight web view
- `tree` for generating a static HTML directory listing at boot
- `hdparm` for HDD power-management settings

## Boot-time behavior

The included `rc.local` file documents the original boot-time workflow:

1. print the current IP address,
2. mount the attached storage device at `/nas`,
3. bind-mount `/nas` into MiniHTTPD's web root,
4. apply HDD standby and power-management settings with `hdparm`,
5. generate a static HTML directory tree with `tree`,
6. start MiniHTTPD after a short delay.

The generated tree output is written to:

```text
/nas/tree.html
```

In the original setup this was a simple boot-time snapshot, not a cron-based recurring refresh.

## Network services

The build exposes files in two simple ways:

- Samba provides file sharing on the local network.
- MiniHTTPD serves a lightweight web-accessible directory view.

The `mini-httpd.conf` file is kept as an example configuration. Any local IP addresses in the public repository should be treated as documentation placeholders and replaced with the actual LAN address of the device.

## Images

WDPi project image:

![WDPi project image](wdpi.gif)

WDPi picture of later version:

![WDPi later version](wdpi_rev1.jpg)

## Known limitations

- This is an old hardware/software snapshot, not an actively maintained NAS image.
- The operating system and packages are not updated as part of this repository.
- MiniHTTPD and the static `tree.html` view are minimal convenience tools, not a modern web file manager.
- The boot workflow depends on historical device naming such as `/dev/sda` and `/dev/sda1`; modern deployments should use UUIDs, labels, or systemd mount units.
- The `rc.local` approach reflects the original deployment era. A current Linux setup would normally use systemd units and explicit dependencies.
- The `tree.html` output is generated at boot only unless the workflow is extended.
- Do not expose this setup directly to the public internet without a security review, authentication, current packages, firewalling, and transport security.

## Authorship and media rights

Project documentation and photographs by Tomáš Gál, unless otherwise noted.

External project links are included for hardware identification and historical context.
