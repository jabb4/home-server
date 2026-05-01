# SLZB-MR4U

The SMLIGHT SLZB-MR4U Multiradio is the dedicated Zigbee2MQTT radio
coordinator for Home Assistant.

## Network

- IP: `10.0.20.61`
- Subnet: `10.0.20.0/24`
- Gateway: `10.0.20.1`
- DNS: `10.0.20.53`
- Network role: Services VLAN infrastructure
- Connectivity: Ethernet/PoE

Keep the coordinator on the Services VLAN with the Home Assistant host. It is a
privileged bridge into the home automation radio networks, not a generic IoT
client device.

## Access Model

- Home Assistant on `10.0.20.60` may connect to the coordinator socket.
- Admin clients may access the SLZB-OS web UI for setup and firmware updates.
- IoT, guest, and untrusted client networks should not be allowed to access the
  coordinator directly.
- The SLZB-OS web UI should not be published through Traefik.

Minimum firewall intent:

- `10.0.20.60` to `10.0.20.61` on the active Zigbee socket port, commonly TCP
  `6638`.
- Admin LAN to `10.0.20.61` for SLZB-OS management.
- IoT, guest, and untrusted networks to `10.0.20.61`: deny.

## Radio Plan

- Use `CC2674P10` for the fresh Zigbee network.
- Keep `EFR32MG26` available for Thread/Matter later.
- Use Zigbee2MQTT with the `zstack` adapter.
- Do not configure ZHA for this deployment.
- Do not keep the old SONOFF ZBDongle-E running as a second coordinator.
- The old SONOFF dongle can be reflashed as a Zigbee router later if useful.

Confirm the exact socket path and radio mapping in SLZB-OS before configuring
Zigbee2MQTT. The default SMLIGHT socket port is commonly `6638`, but the active
port should be treated as device configuration.

Zigbee2MQTT serial setting:

```yaml
serial:
  port: tcp://10.0.20.61:6638
  adapter: zstack
```

## Fresh Zigbee Install Notes

The current plan is a fresh Zigbee network instead of migrating coordinator
state from the SONOFF ZBDongle-E.

1. Bring the SLZB-MR4U online at `10.0.20.61`.
2. Update SLZB-OS and record the radio firmware and socket settings.
3. Configure `CC2674P10` as the Zigbee coordinator over Ethernet.
4. Unplug the SONOFF ZBDongle-E before starting the new Zigbee network.
5. Start Zigbee2MQTT with `adapter: zstack`.
6. If Zigbee2MQTT shows the onboarding UI, choose the option that uses the
   existing/app configuration.
7. Pair mains-powered Zigbee routers first, such as plugs, bulbs, and relays.
8. Pair battery devices after the router mesh is in place.
9. Rebuild groups, bindings, dashboards, and automations after entity names are
   stable.

Avoid changing VLAN design during the Zigbee rebuild. A broader IoT network can
be introduced later after Home Assistant and Zigbee are stable.

## References

- [SMLIGHT SLZB-MR4U](https://smlight.tech/us/slzbmr4)
- [SMLIGHT SLZB-OS manuals](https://smlight.tech/support/manuals/books/slzb-os)
- [Zigbee2MQTT adapter settings](https://www.zigbee2mqtt.io/guide/configuration/adapter-settings.html)
- [How to Set Up the SLZB-06 Zigbee Coordinator in Home Assistant](https://www.youtube.com/watch?v=8bf5IH1iY_E)
