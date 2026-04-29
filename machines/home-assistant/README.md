# Home Assistant

Home Assistant runs outside Kubernetes on a dedicated Raspberry Pi at
`10.0.20.60` and is published through the Kubernetes Traefik external route.

## Network

- IP: `10.0.20.60`
- Subnet: `10.0.20.0/24`
- Gateway: `10.0.20.1`
- DNS: `10.0.20.53`
- Network role: Services VLAN infrastructure
- Host: `home-assistant.local.jabbas.dev`
- Backend: `http://10.0.20.60:8123`

Use a UniFi DHCP reservation for the Raspberry Pi MAC address rather than a
static address configured only on the Pi.

## Reverse Proxy

When Home Assistant is behind Traefik, it must trust the proxy IPs that send
`X-Forwarded-For`. If not, the UI loads poorly and websocket requests to
`/api/websocket` fail with `400`.

Typical Home Assistant log symptom:

```text
Received X-Forwarded-For header from an untrusted proxy 10.0.20.21
```

Configure Home Assistant with:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.0.20.0/24
```

After changing `configuration.yaml`, restart Home Assistant.

## Migration Notes

Current migration direction:

1. Keep Home Assistant running on Stratton until the new Raspberry Pi install
   is ready.
2. Bring the SLZB-MR4U online at `10.0.20.61`.
3. Build a fresh Zigbee network on the SLZB-MR4U rather than migrating the old
   SONOFF coordinator state.
4. Move Home Assistant to the Raspberry Pi at `10.0.20.60`.
5. Update the Traefik external route to `10.0.20.60:8123`.
6. Re-pair Zigbee devices and repair automations after entity names are stable.

Reference:

- [Home Assistant HTTP integration](https://www.home-assistant.io/integrations/http/)
