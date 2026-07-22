# Maintenance record — 2026-07-22

This document records Wi-Fi driver stabilization and router-side changes on the continuously operated WDPi server. It is sanitized and omits the wireless network name, passphrase, access-point addresses, public hostnames and other private identifiers.

## Hardware and driver

The server uses an Edimax USB Wi-Fi adapter identified by USB ID `7392:a811`. It is handled by the out-of-tree Realtek `8812au` driver rather than an in-kernel mac80211 driver.

The installed module was recorded as:

```text
module: 8812au
version: v4.2.2_7502.20130517
kernel: 4.9.51-v7+
path: /lib/modules/4.9.51-v7+/kernel/drivers/net/wireless/8812au.ko
```

This is an old vendor driver retained for compatibility with the original Raspbian Jessie deployment. Its behavior and reporting differ from current in-kernel wireless drivers. For example, `wpa_cli` reported an active completed association but returned `freq=0`, while `iwconfig` correctly showed the actual 5 GHz frequency.

## Driver power-management configuration

The device is a permanently powered server, so driver-level power-saving features were disabled in favor of stable connectivity. The active module configuration is preserved in sanitized form as [`../config/8812au.conf`](../config/8812au.conf):

```text
options 8812au rtw_ips_mode=0 rtw_power_mgnt=0 rtw_low_power=0 rtw_enusbss=0
```

The USB device power policy was also observed as `on`, and wireless power management reported as disabled. These settings reduce the number of independent power-saving mechanisms that can suspend or partially deactivate the legacy adapter.

## IPv4-only wireless interface

The appliance is intentionally operated over IPv4 on its trusted local network. IPv6 was therefore disabled specifically for `wlan0`, without applying a global IPv6 disable. The sanitized sysctl configuration is available as [`../config/99-disable-ipv6-wlan0.conf`](../config/99-disable-ipv6-wlan0.conf).

## Router-side adjustment

The router uses a Smart Connect or band-steering configuration in which the same wireless network name is available across multiple radios. During maintenance, the 5 GHz channel-width setting was reduced from `20/40/80 MHz` to `20/40 MHz`. The server subsequently associated over 802.11ac on the 5 GHz band and remained reachable through SSH.

This is an operational observation rather than proof that channel width alone caused the improved association. Driver power-management settings, router steering and the renewed association were all changed or exercised during the same maintenance window.

## Fixed BSSID test and rollback

A fixed `wpa-bssid` entry was temporarily added in an attempt to keep the server on one particular 5 GHz access point. With Smart Connect enabled, this proved unreliable: after reboot, the server did not associate with the wireless network.

The fixed BSSID was removed, after which a normal `ifdown` and `ifup` cycle restored connectivity. Without BSSID pinning, the server again selected a 5 GHz access point automatically.

The resulting rule is:

- do not pin this deployment to a specific access-point BSSID while the router is using Smart Connect or band steering;
- allow the router and supplicant to select among access points advertising the configured network;
- use a separate 5 GHz-only network name at the router if strict band selection is later required.

A runtime `wpa_supplicant` frequency list covering the common lower 5 GHz channels was also tested successfully. It was not written into the persistent interface configuration, because the automatic Smart Connect association was working and avoiding another boot-time restriction was considered safer.

## Validated final state

After rollback of the fixed BSSID configuration:

- `wpa_state` reported `COMPLETED`;
- the adapter was associated through 802.11ac on 5 GHz;
- wireless power management remained disabled;
- the server was reachable through SSH;
- no wireless credentials or access-point identifiers were added to this repository.

The persistent changes represented in this repository are limited to the driver power-management parameters and the interface-specific IPv6 sysctl setting.
