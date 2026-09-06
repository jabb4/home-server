# Homelab Architecture

This repository is the source of truth for Jabbas current homelab.

Current operating model:

- `main` is the GitOps source branch. Dockhand on Infra PI pulls compose stacks
  from this repo and reconciles them on the Docker hosts it manages.
- All user services run as Docker Compose stacks besides Home Assistant.
- Services is the always-on control Ingress, GitOps, auth and the dashboard.


## Repo Layout

- `machines/`: Holds the documentation of all the machines running in the homelab and how to deplay / set them up.
- `services/`: Hold all the config files and dockumentation for the services running
- `scripts/`: repo-level helper scripts
- `docs/`: Documentation that doesnt fit else where like docker instructions etc.


## Network Layout

| Network | Subnet | Purpose | Current Use |
| --- | --- | --- | --- |
| Reserved | `10.0.1.0/24` | Unused netowrk (VLAND ID 1) | None |
| Home | `10.0.10.0/24` | Safe devices belonging to the home | Phones, computers, ... |
| Infra | `10.0.20.0/24` | always-on infrastructure | Core PI (Traefik, Dockhand, Homepage), Media PI, Home Assistant, SLZB-MR4U |
| IoT | `10.0.99.0/24` | IoT devices that are "unsafe" and should be isolated | Sonos speakers, smart scale, Air purifyer etc. |


## Machines

### Core Pi
- Hardware: Raspberry Pi 5 4GB, RAM 256GB m.2 SSD
- Role: always-on control plane and critical infra
- IP: `10.0.20.53`
- Services: `Traefik`, `Dockhand`, `Homepage`, `Uptime-kuma` (planed), `Authentik` (planed)

### Home Assistant Pi
- Hardware: Raspberry Pi 4 4GB RAM, 128 GB SATA SSD USB 3.0
- Role: home automation controller
- IP: `10.0.20.60`
- Service: `Home Assistant`

### SLZB-MR4U
- Hardware: SMLIGHT SLZB-MR4U Multiradio
- Role: Zigbee and Thread coordinator
- IP: `10.0.20.61`
- Service: Zigbee2MQTT radio coordinator

### Media Pi
- Hardware: Raspberry Pi 5, 8GB RAM, 1TB m.2 SSD
- Role: Streaming and downloding media content
- IP: `10.0.20.80`
- Services: `Jellyfin`, `gluetun`, `SABnzbd`, `Prowlarr`, `Radarr`, `Sonarr`, `Bazarr`, `Seerr`, 


## GitOps Model

Dockhand runs on Core PI at `https://dockhand.local.jabbas.dev` and:

1. Watches this repository on branch `main`.
2. Pulls the Compose files for each registered stack from the path that owns
   them under `services/<service>/`.
3. Reconciles each stack on the host it was assigned to (Core PI or Media PI).

Local edits do not affect the live cluster until they are committed and pushed
to `main`.

## Ingress

Core PI Traefik is the single edge proxy. Every `*.local.jabbas.dev` name resolves
to Core PI through a wildcard DNS record on the UniFi gateway and is routed by
Traefik to the correct backend on the LAN. Traefik holds a Let's Encrypt wildcard
cert for `*.local.jabbas.dev` via the Cloudflare DNS-01 challenge.

The full route table lives in [`services/traefik/README.md`](services/traefik/README.md).
