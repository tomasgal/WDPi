# Maintenance record — 2026-07-15

This is a sanitized consolidation of the FTP, ACL and mount repairs performed on the running WDPi server. It omits credentials, public DNS names, IP addresses, private filenames and real filesystem UUIDs.

## Initial state

The server was still running a Jessie-era Raspbian installation with Samba, vsftpd and remnants of older ProFTPD/OpenMediaVault configuration. FTP was operational, but the configuration and permission model had accumulated several inconsistencies:

- anonymous FTP had broad write directives;
- directory access depended on legacy ownership and ACL state;
- the Unix account used by anonymous FTP was unnecessarily a member of `sudo` and had a passwordless sudo rule available through group membership;
- vsftpd contained a malformed duplicated certificate/configuration line;
- local FTP users were rooted through historical home-directory symlinks;
- mounts were initiated from root's crontab with device names and an incorrect uppercase `-O` option;
- the nested upload mount could be hidden or replaced by an ordinary directory if boot ordering failed;
- a printer-specific FTP destination did not yet exist.

## Backups made

Before permission and boot changes, the following classes of backup were created locally on the server:

- a copy of the active vsftpd configuration;
- a recursive `getfacl` export of the FTP tree;
- a copy of `/etc/fstab`;
- a copy of root's crontab.

These backups are not committed because they contain local paths, account names and filesystem metadata.

## Account hardening

The Unix account used by anonymous FTP was removed from the `sudo` group. Its primary group was changed to a dedicated FTP group.

A positive vsftpd allowlist was introduced. Only the two intended human FTP users, anonymous aliases and the isolated scanner account are accepted by vsftpd. Historical Samba-only accounts remain outside the FTP allowlist.

The scanner account was created with:

- a private FTP directory;
- an interactive-login shell set to `/usr/sbin/nologin`;
- `/usr/sbin/nologin` listed in `/etc/shells` so that `pam_shells.so` permits FTP authentication while interactive shell login remains disabled;
- no sudo membership;
- no Samba account requirement.

## vsftpd cleanup

The malformed duplicated certificate line was removed. The active configuration was consolidated around:

- global local root `/ftp`;
- anonymous root `/ftp`;
- local-user chroot;
- positive user allowlisting;
- anonymous upload/mkdir/rename/delete support constrained by ACLs;
- hidden numeric identities in directory listings;
- a generic banner file;
- per-user configuration support;
- a scanner-specific local root;
- hiding and denying `lost+found`;
- `anon_world_readable_only=NO`.

### Directory-listing fault

After ACL normalization, anonymous upload still worked but anonymous directory listings in `share` and `upload` appeared empty. The FTP response ended with:

```text
226 Transfer done (but failed to open directory).
```

Local permission tests under the anonymous Unix account succeeded. `strace` confirmed that vsftpd could `chdir` into and open the directory. The root cause was vsftpd's default `anon_world_readable_only=YES`: files readable through an ACL, but not through traditional world-readable mode bits, were suppressed.

Adding:

```ini
anon_world_readable_only=NO
```

made vsftpd respect the intended effective ACL access. No additional ACL for the unprivileged helper account was needed; the temporary diagnostic ACL was removed.

## Access-control model

The FTP tree was adjusted to implement this policy:

| Area | Owner user | Other human user | Anonymous FTP | Scanner |
|---|---:|---:|---:|---:|
| Owner's personal area | RW | R | none | none |
| Shared area | RW | RW | R | none |
| Upload area | RW | RW | RW | none |
| Scanner area | R | R | none | RW |

POSIX ACLs were used instead of world access. Default ACLs were added where new files must inherit shared access.

The `lost+found` directory on the upload filesystem was accidentally included in an initial recursive ACL normalization. Its extended and default ACLs were removed, ownership was restored to `root:root`, and its mode was restored to `0700`. It was then hidden and denied globally through vsftpd.

## FTP validation

The following protocol-level tests succeeded:

- anonymous login;
- anonymous directory listing in `share` and `upload`;
- anonymous download from `share`;
- denial of anonymous upload to `share`;
- anonymous upload and deletion in `upload`;
- denial of anonymous access to personal directories;
- authenticated login for a human user;
- authenticated write to the user's own area;
- authenticated read but denied write to the other user's area;
- authenticated write to `share`;
- anonymous read of a newly created shared file;
- scanner account login and upload;
- read access by the human users to a scanner-created test file.

## Scanner FTP destination

A dedicated account and directory were added for a Pantum multifunction printer's FTP address-book / scan-to-FTP function.

The scanner account sees its private physical directory as FTP `/`, cannot traverse above it, and can read and write only within that root. The two human users have read-only access to the resulting scan files.

The server-side account and upload path were tested. A scan initiated physically from the printer remains pending.

## Storage and boot ordering

Observed storage mapping:

- primary data filesystem: WD storage device mounted at `/ftp`;
- upload filesystem: Kingston USB flash drive mounted at `/ftp/upload`;
- system and boot filesystems: MMC device.

The old root crontab used commands equivalent to:

```text
mount -t ext4 -O ... /dev/sda1 /ftp
mount -t ext4 -O ... /dev/sdb1 /ftp/upload
```

This was problematic because:

- uppercase `-O` is a filesystem-option filter, not the mount-option switch `-o`;
- `/dev/sdX` names are not persistent identifiers;
- fixed sleeps do not express the nested dependency;
- failure of the upload mount could leave an ordinary `/ftp/upload` directory writable on the primary disk.

The two mount commands were removed from root's crontab. Sanitized UUID-based entries were added to `/etc/fstab`, with the parent mount listed before the nested upload mount and with `nofail` to preserve base-system boot and SSH access when external storage is unavailable.

A systemd override for vsftpd now contains:

```ini
[Unit]
RequiresMountsFor=/ftp /ftp/upload
After=local-fs.target
```

`systemctl show` confirmed dependencies on both generated mount units. Both mount units were active, and vsftpd restarted successfully after the override was loaded.

## Current completion state

Completed:

- FTP account allowlisting;
- anonymous account privilege reduction;
- intended ACL matrix;
- anonymous listing fix;
- `lost+found` protection;
- scanner FTP account and chroot;
- UUID-based mount definitions;
- removal of data mounts from cron;
- vsftpd dependency on both data mounts;
- protocol-level functional tests.

Pending acceptance checks:

- cold reboot validation;
- physical scan-to-FTP test;
- migration planning for the obsolete operating system;
- review of encrypted or restricted-access alternatives where legacy-client compatibility permits them.
