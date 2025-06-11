# Climate Gateway Torizon Base Image

This is our customized base image for the Climate Gatway.
We adjusted the follwing:

- Suitable Device Tree for Ivy Board
- TailScale for remote SSH connections

## Build & Deploy

To build and deploy you can use our bespoke scripts, which will make use of the torizon-core-builder.
This is a way more flexible and versatile approach than working with the tcb plugin and the Toradex scripts...

More info will follow...

## Settings on Device after Deploy

### Common Settings
- Hostname set
- SSH Key Deployed
- SSH Password Authentication disabled

### Network

```
nmcli con mod network0 \
    ipv4.dhcp-timeout 2147483647 \
    ipv4.may-fail yes \
    ipv4.link-local enabled

nmcli con mod network1 \
    ipv4.dhcp-timeout 2147483647 \
    ipv4.may-fail yes \
    ipv4.link-local enabled
```

Explanation:
- ipv4.dhcp-timeout 2147483647: DHCP timeout infinite (MAXINT32)
    - Otherwise NetworkManager (NM) would disconnect and remove all IP's after all retries (default 4)
- ipv4.may-fail yes: The connection is allowed to fail
    - This is needed so the IP stays there even if there is "no connection" from NM's viewpoint
- ipv4.link-local fallback: If there is no DHCP IP fallback to link-local

# Release Overview

This table shows the version of ClimateGatewayBase and on which Toradex BSP it is built on.

| ClimateGatewayBase | Toradex BSP Version        |
|--------------------|----------------------------|
| v0.1.0             | 7.3.0-devel-202505+build.8 |
| v0.1.1             | 7.3.0-devel-202505+build.8 |
