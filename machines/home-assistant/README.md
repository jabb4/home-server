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

## Zigbee2MQTT

Zigbee is managed through Zigbee2MQTT, not ZHA.

Use the Home Assistant OS app flow with the official Mosquitto broker app.

Use the internal Home Assistant app hostname for Mosquitto:

```text
mqtt://core-mosquitto:1883
```

Do not point Zigbee2MQTT at `10.0.20.60:1883` unless the broker is explicitly
published outside Home Assistant OS.

Zigbee2MQTT app repository:

```text
https://github.com/zigbee2mqtt/hassio-zigbee2mqtt
```

Setup checklist:

1. Install the Mosquitto broker app from `Settings > Apps`.
2. Enable `Start on boot`, `Watchdog`, and `Auto-update` for Mosquitto.
3. Start Mosquitto and confirm the logs show a successful startup.
4. Add or confirm the Home Assistant MQTT integration under
   `Settings > Devices & Services`.
5. Create the `zigbee2mqtt` user under `Settings > People > Users`.
   Do not use reserved usernames such as `homeassistant` or `addons`.
6. Add the Zigbee2MQTT app repository.
7. Install the stable Zigbee2MQTT app, not Edge, unless a specific bug requires
   Edge.
8. Configure Zigbee2MQTT to use the SLZB-MR4U at `10.0.20.61`.
9. Start Zigbee2MQTT and check the app logs before pairing devices.

On first start, Zigbee2MQTT may open the onboarding UI before the normal
frontend. If the app configuration already contains the MQTT and serial
settings, choose the option that uses the existing/app configuration, instead
of trying to rediscover or recreate the configuration in the onboarding UI.

Zigbee2MQTT configuration skeleton:

```yaml
version: 5

mqtt:
  base_topic: zigbee2mqtt
  server: mqtt://core-mosquitto:1883
  user: zigbee2mqtt
  password: change-me

serial:
  port: tcp://10.0.20.61:6638
  adapter: zstack

advanced:
  channel: 20
  network_key: GENERATE
  pan_id: GENERATE
  ext_pan_id: GENERATE

frontend:
  enabled: true

homeassistant:
  enabled: true
```

Pick the Zigbee channel before pairing devices. Use one of the common ZLL
channels `11`, `15`, `20`, or `25`; this install currently documents `20` as
the default choice. Changing the channel or network key later can require
repairing devices.

## UPS Monitoring

Home Assistant uses the Network UPS Tools integration to display UPS status
from the NUT controller at `192.168.20.70`.

For read-only monitoring in Home Assistant, credentials are not required:

```text
Host: 192.168.20.70
Port: 3493
```

The NUT `upsremote` user is only needed for systems configured as NUT shutdown
clients, such as hosts running `upsmon` to shut down automatically on low
battery.

## Migration Notes

Current migration direction:

1. Keep Home Assistant running on Stratton until the new Raspberry Pi install
   is ready.
2. Bring the SLZB-MR4U online at `10.0.20.61`.
3. Build a fresh Zigbee2MQTT network on the SLZB-MR4U rather than migrating the
   old SONOFF coordinator state.
4. Move Home Assistant to the Raspberry Pi at `10.0.20.60`.
5. Update the Traefik external route to `10.0.20.60:8123`.
6. Re-pair Zigbee devices and repair automations after entity names are stable.

Reference:

- [Home Assistant HTTP integration](https://www.home-assistant.io/integrations/http/)
- [Zigbee2MQTT Home Assistant add-on](https://www.zigbee2mqtt.io/guide/installation/03_ha_addon.html)
- [How to Set Up the SLZB-06 Zigbee Coordinator in Home Assistant](https://www.youtube.com/watch?v=8bf5IH1iY_E)
