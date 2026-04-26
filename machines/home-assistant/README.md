# Home Assistant

Home Assistant runs outside Kubernetes on a Raspberry Pi at `10.0.20.60` and is
published through the Kubernetes Traefik external route:

- Host: `home-assistant.local.jabbas.dev`
- Backend: `http://10.0.20.60:8123`
- Network: Services VLAN, `10.0.20.0/24`

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

Reference:

- [Home Assistant HTTP integration](https://www.home-assistant.io/integrations/http/)
