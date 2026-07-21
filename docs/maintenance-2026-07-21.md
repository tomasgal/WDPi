# Maintenance record — 2026-07-21

This document records the production migration to the native Samba 4.10.18 build, removal of a duplicate DHCP manager, and post-reboot validation. It is sanitized and omits credentials, public hostnames, routable addresses, real filesystem UUIDs and private filenames.

## Starting point

The WDPi server was running the packaged Samba 4.2 daemons on Raspbian Jessie. A native Samba 4.10.18 build had already been compiled and validated in isolation under `/opt/samba-4.10.18`.

The server also had two DHCP managers active on the same Wi-Fi interface:

- `dhclient`, launched by `networking.service` together with `wpa_supplicant`;
- `dhcpcd`, launched as a separate system service.

The duplicate configuration was not merely theoretical. Historical `dhcpcd` logs showed it removing the active IPv4 address, connected route and default route while `dhclient` was also managing the interface.

## Production Samba migration

The production `smbd` and `nmbd` services were replaced with native systemd units that start:

```text
/opt/samba-4.10.18/sbin/smbd
/opt/samba-4.10.18/sbin/nmbd
```

Both units use the existing shared configuration:

```text
/etc/samba/smb.conf
```

The units run the daemons in the foreground with `--no-process-group` and explicitly set Samba's runtime directories:

```text
lock directory=/var/run/samba
state directory=/var/lib/samba
cache directory=/var/cache/samba
private dir=/var/lib/samba/private
pid directory=/var/run/samba
```

Each unit also uses `RequiresMountsFor=/ftp`, ensuring that the data filesystem is available before Samba starts.

The packaged Samba 4.2 files remain installed. They were not overwritten or removed, but their daemon binaries are no longer used by the active services.

## Samba validation before reboot

The active production services were checked for:

- successful startup of both `smbd.service` and `nmbd.service`;
- executable paths resolving to `/opt/samba-4.10.18`;
- version output reporting Samba 4.10.18;
- TCP listeners on ports 139 and 445;
- successful authenticated connection to the production share;
- fast directory listing after an authenticated SMB session was established.

Multiple `smbd` processes were observed. This is normal Samba behavior: the parent daemon creates helper and per-client processes. They were all instances of the same 4.10.18 executable, not parallel Samba installations.

## Duplicate DHCP cleanup

The intended network path was confirmed as:

```text
kernel USB Wi-Fi driver
    -> wlan0
    -> wpa_supplicant
    -> dhclient
    -> IPv4 address, route and DNS configuration
```

`dhcpcd` was not a Wi-Fi driver and was not required by the USB adapter. It was a second network-configuration daemon competing with `dhclient`.

The service was first disabled and then masked. The running process was terminated without allowing it to remove the active address and routes. Immediate validation confirmed:

- `dhcpcd` no longer running;
- `dhcpcd.service` reported as `masked`;
- `dhclient` remained active;
- the Wi-Fi interface retained its IPv4 address;
- the connected route and default route remained present;
- the local gateway remained reachable.

## Reboot validation

A full reboot was then performed. After startup, the following were confirmed:

### Network

- `wlan0` was up and associated;
- the expected IPv4 address was assigned;
- the connected route and default route were present;
- exactly one `dhclient` process was active;
- `dhcpcd` was not running and remained masked;
- SSH access was available immediately after the system completed booting.

### Samba

- `smbd.service` was active and enabled;
- `nmbd.service` was active and enabled;
- every active `smbd` and `nmbd` executable resolved to `/opt/samba-4.10.18`;
- all active Samba daemons reported version 4.10.18;
- `smbd` listened on TCP 139 and 445;
- `nmbd` listened on UDP 137 and 138;
- authenticated local SMB access to the production share succeeded;
- directory listing returned the expected storage tree.

The old Jessie `ss` utility did not display the NetBIOS UDP sockets in the initial filtered command, but `netstat -lunp` confirmed all expected `nmbd` listeners on the interface address, broadcast address and wildcard sockets.

## Performance observation

Before explicit authentication, a Windows SMB access attempt had previously waited for approximately 20 seconds and failed. After the network cleanup and explicit creation of a valid SMB session, authenticated connection setup completed in a few seconds including manual password entry, and the subsequent directory listing completed in tens of milliseconds.

This does not prove that the duplicate DHCP daemon caused every earlier SMB delay. Authentication state and the Samba migration also changed. It does establish that the duplicate network manager was a real configuration defect capable of removing the server's address and routes, and that the final post-reboot network and SMB behavior was normal.

## Final state

The validated production arrangement is:

```text
networking.service
├── wpa_supplicant
└── dhclient

smbd.service
└── /opt/samba-4.10.18/sbin/smbd

nmbd.service
└── /opt/samba-4.10.18/sbin/nmbd
```

All three service paths survived a full reboot. The remaining acceptance work is unrelated to this migration: a physical scan-to-FTP operation from the multifunction printer and longer-term migration planning for the obsolete operating system.
