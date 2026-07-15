# Sanitized configuration examples

These files document the current logical WDPi arrangement without publishing credentials or host-specific identifiers.

## Included examples

- `vsftpd.conf.example` — global vsftpd configuration
- `vsftpd.user_list.example` — positive FTP login allowlist
- `vsftpd_user_conf/scanner` — isolated scanner account root
- `welcome.msg.example` — generic FTP banner
- `pam.d/vsftpd.example` — PAM stack used by vsftpd
- `samba-share.conf.example` — Samba share block for `/ftp`
- `fstab.data.example` — UUID-based parent and nested data mounts
- `systemd/vsftpd.service.d/mounts.conf` — mount dependencies for vsftpd
- `acl-layout.example.sh` — example ACL policy for a new directory layout

## Placeholders

Replace the following locally:

- `primary_user`
- `secondary_user`
- `scanner`
- `<PRIMARY_DATA_UUID>`
- `<UPLOAD_DATA_UUID>`
- local passwords and network addresses

Do not commit real passwords, password hashes, public hostnames, IP addresses, certificate private keys or filesystem UUIDs.

## Important

These examples reflect an old compatibility-oriented system. They are not a secure-by-default prescription for a new internet-facing FTP server. Review paths, accounts, groups, passive-mode firewalling, encryption requirements and operating-system support before deployment.
