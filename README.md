# Homelab Architecture

This repository is the source of truth for the current Stratton homelab.

Current operating model:

- `main` is the GitOps source branch. Dockhand on Rocky pulls compose stacks
  from this repo and reconciles them on the Docker hosts it manages.
- `Stratton` runs `Proxmox VE` and hosts the apps VM and TrueNAS.
- All user services run as Docker Compose stacks. No Kubernetes.
- Rocky is the always-on control plane: DNS, ingress, GitOps, and the dashboard.

## Repo Layout

- `machines/rocky/docker-services/`
  - `dockhand/`, `pi-hole/` — bootstrap stacks brought up by hand; not managed
    by Dockhand because a bad reconcile to either would break the GitOps
    control plane (repo pull or DNS)
  - `managed/` — Dockhand-managed Compose stacks on Rocky: `homepage`, `traefik`
- `machines/stratton/vms/apps/docker-services/managed/`
  - Dockhand-managed Compose stacks on `apps-vm`: `jellyfin`, `media-downloader`,
    `recyclarr`
- `machines/stratton/`
  - Proxmox host notes and BIOS setup
- `nixos/`
  - NixOS host config for `apps-vm`
- `machines/home-assistant/`, `machines/rocky/`, `machines/jordan/`,
  `machines/nut/`, `machines/slzb-mr4u/`
  - docs and host-specific notes for the non-Stratton machines
- `scripts/`
  - repo-level helper scripts

## Network Layout

| Network | Subnet | Purpose | Current Use |
| --- | --- | --- | --- |
| Default LAN | `192.168.10.0/24` | user devices and admin workstation | client origin network |
| Management | `10.0.10.0/24` | admin-only interfaces | Proxmox, switch/AP management, other host admin surfaces |
| Services | `10.0.20.0/24` | always-on infrastructure | Rocky (Pi-hole, Traefik, Dockhand, Homepage), Home Assistant, SLZB-MR4U |
| VM Network | `192.168.20.0/24` | Stratton VMs | TrueNAS, `apps-vm`, NUT |

## Address Highlights

| IP | Use |
| --- | --- |
| `10.0.10.10` | Stratton Proxmox management |
| `10.0.20.53` | Rocky (Pi-hole DNS, Traefik ingress, Dockhand, Homepage) |
| `10.0.20.60` | Home Assistant Raspberry Pi |
| `10.0.20.61` | SLZB-MR4U Zigbee/Thread coordinator |
| `192.168.20.70` | NUT UPS controller |
| `192.168.20.101` | TrueNAS |
| `192.168.20.103` | `apps-vm` (Jellyfin + media-downloader stack) |

## Core Machines

### Stratton

- Host role: main virtualization host
- Host OS: `Proxmox VE`
- Runs:
  - `apps-vm` (streaming + downloading)
  - `TrueNAS`

### Rocky

- Hardware: Raspberry Pi 5
- Role: always-on control plane
- Services: `Pi-hole`, `Traefik`, `Dockhand`, `Homepage`

### Home Assistant

- Hardware: Raspberry Pi
- Role: home automation controller
- IP: `10.0.20.60`
- Service: `Home Assistant`

### Jordan

- Hardware: Raspberry Pi 4
- Role: out-of-band access
- Service: `PiKVM`

### NUT

- Hardware: Raspberry Pi 3b+
- Role: UPS monitoring and shutdown orchestration
- Service: `NUT`

### SLZB-MR4U

- Hardware: SMLIGHT SLZB-MR4U Multiradio
- Role: Zigbee and Thread coordinator
- IP: `10.0.20.61`
- Service: Zigbee2MQTT radio coordinator

## GitOps Model

Dockhand runs on Rocky at `https://dockhand.local.jabbas.dev` and:

1. Watches this repository on branch `main`.
2. Pulls the Compose files for each registered stack from the path that owns
   them under `machines/<host>/docker-services/managed/<service>/`.
3. Reconciles each stack on the host it was assigned to (Rocky or `apps-vm`).

Local edits do not affect the live cluster until they are committed and pushed
to `main`.

## Ingress

Rocky Traefik is the single edge proxy. Every `*.local.jabbas.dev` name resolves
to Rocky through the Pi-hole wildcard `address=/local.jabbas.dev/10.0.20.53` and
is routed by Traefik to the correct backend on the LAN. Traefik holds a
Let's Encrypt wildcard cert for `*.local.jabbas.dev` via the Cloudflare DNS-01
challenge.

The full route table lives in
[`machines/rocky/docker-services/managed/traefik/README.md`](machines/rocky/docker-services/managed/traefik/README.md).

## Services Running on `apps-vm`

- `Jellyfin`
- media-downloader stack (`gluetun`, `SABnzbd`, `Prowlarr`, `Sonarr`, `Radarr`,
  `Bazarr`, `Seerr`)
- `Recyclarr`

Large file libraries live on `TrueNAS NFS` and are mounted into the apps VM.

## Key Docs

- Rocky control plane:
  [`machines/rocky/README.md`](machines/rocky/README.md)
- Rocky Traefik (ingress):
  [`machines/rocky/docker-services/managed/traefik/README.md`](machines/rocky/docker-services/managed/traefik/README.md)
- Dockhand (GitOps):
  [`machines/rocky/docker-services/dockhand/README.md`](machines/rocky/docker-services/dockhand/README.md)
- Home Assistant:
  [`machines/home-assistant/README.md`](machines/home-assistant/README.md)
- SLZB-MR4U coordinator:
  [`machines/slzb-mr4u/README.md`](machines/slzb-mr4u/README.md)
- TrueNAS note:
  [`machines/stratton/vms/truenas/README.md`](machines/stratton/vms/truenas/README.md)
