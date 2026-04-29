# Homelab Architecture

This repository is the source of truth for the current Stratton homelab.

Current operating model:

- `main` is the GitOps source branch for the Kubernetes cluster
- `Stratton` runs `Proxmox VE` and hosts the Talos Kubernetes nodes plus the
  remaining non-Kubernetes VMs
- cluster infrastructure now lives mostly in Kubernetes
- a smaller set of services still runs on dedicated VMs or hardware where that
  is currently simpler or safer

## Repo Layout

- `machines/stratton/k8s/`
  - Talos bootstrap workflow, cluster patches, Argo bootstrap, and Kubernetes
    workloads
- `machines/stratton/vms/`
  - VM-level notes for `cp-1`, `worker-1`, `apps`, `dmz`, `truenas`, and
    other Stratton-hosted VMs
- `nixos/`
  - NixOS host configs for the VMs that still use them, currently `apps-vm`
    and `dmz-vm`
- `machines/home-assistant/`, `machines/rocky/`, `machines/jordan/`,
  `machines/nut/`, `machines/slzb-mr4u/`
  - docs and host-specific notes for the non-Stratton machines
- `scripts/`
  - repo-level helper scripts

For the k8s cluster setup, follow
[`machines/stratton/k8s/setup.md`](machines/stratton/k8s/setup.md).

## Network Layout

| Network | Subnet | Purpose | Current Use |
| --- | --- | --- | --- |
| Default LAN | `192.168.10.0/24` | user devices and admin workstation | client origin network |
| Management | `10.0.10.0/24` | admin-only interfaces | Proxmox, switch/AP management, other host admin surfaces |
| Services | `10.0.20.0/24` | Kubernetes nodes and internal service ingress | Talos nodes, Kubernetes API VIP, Traefik load balancer, Pi-hole, Home Assistant, SLZB-MR4U |
| Legacy VM Network | `192.168.20.0/24` | VMs and services not yet moved into Kubernetes or changed VLAN | `TrueNAS`, `apps-vm`, `dmz-vm`, `NUT` |

The old legacy VM network is still active. A dedicated DMZ VLAN may still be
introduced later, but it is not the current live layout.

## Address Highlights

| IP | Use |
| --- | --- |
| `10.0.10.10` | Stratton Proxmox management |
| `10.0.20.10` | Kubernetes API VIP |
| `10.0.20.11` | `cp-1` Talos control plane |
| `10.0.20.21` | `worker-1` Talos worker |
| `10.0.20.53` | Pi-hole|
| `10.0.20.60` | Home Assistant Raspberry Pi |
| `10.0.20.61` | SLZB-MR4U Zigbee/Thread coordinator |
| `10.0.20.80` | Traefik load balancer IP |
| `192.168.20.70` | NUT UPS controller |
| `192.168.20.101` | TrueNAS |
| `192.168.20.102` | `dmz-vm` |
| `192.168.20.103` | `apps-vm` |

## Core Machines

### Stratton

- Host role: main virtualization host
- Host OS: `Proxmox VE`
- Runs:
  - `cp-1`
  - `worker-1`
  - `TrueNAS`
  - `apps-vm`
  - `dmz-vm`

### Home Assistant

- Hardware: Raspberry Pi
- Role: home automation controller
- IP: `10.0.20.60`
- Service: `Home Assistant`

### Rocky

- Hardware: Raspberry Pi 5
- Role: DNS services
- Services: `Pi-hole`

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
- Service: Home Assistant radio coordinator

## Kubernetes on Stratton

Bootstrap and operations are managed from
[`machines/stratton/k8s/justfile`](machines/stratton/k8s/justfile).

### Cluster Shape

- `cp-1`: single Talos control plane node on `10.0.20.11`
- `worker-1`: single Talos worker on `10.0.20.21`
- API VIP: `10.0.20.10`
- ingress IP: `10.0.20.80`

### Cluster Stack

- `Talos Linux`
- `Kubernetes`
- `Cilium`
- `Argo CD`
- `Longhorn`
- `Traefik`

### Storage Model

- `Longhorn` provides durable in-cluster application state
- the live Longhorn-backed PVCs now use the encrypted `longhorn-crypto`
  storage class
- large shared file libraries stay outside the cluster on `TrueNAS NFS`

### In-Cluster Workloads

#### Cluster Core

- `cluster/foundations`
- `cluster/cilium`
- `cluster/argocd`
- `cluster/longhorn`

#### Shared Infrastructure

- `cert-manager`
- `Traefik`
- `CrowdSec`
- `CloudNativePG`
- `Postgres`
- `Authentik`
- `Prometheus`
- `Grafana`
- `Uptime Kuma`

#### User-Facing Apps in Kubernetes

- `Homepage`

The workload index and conventions live in
[`machines/stratton/k8s/workloads/README.md`](machines/stratton/k8s/workloads/README.md).

## Outside Kubernetes

These services still run outside the cluster today.

### Dedicated VMs

- `TrueNAS`

### Dedicated Hardware

- `Home Assistant` on Raspberry Pi
- `SLZB-MR4U`

### `apps-vm`

- `Jellyfin`
- `MicroBin`
- `Immich` (not up yet)
- `Paperless-NGX` (not up yet)
- media-downloader stack:
  - `Seerr`
  - `SABnzbd`
  - `Radarr`
  - `Sonarr`
  - `Prowlarr`
  - `Bazarr`
- `Recyclarr`

### `dmz-vm`

- `Cloudflared`
- `Tailscale`

Several of the outside-Kubernetes services are still published through Traefik
external routes managed from the cluster, so the ingress plane is already
centralized even where the workloads are not.

## Current Traffic Model

- admin clients originate from `192.168.10.0/24`
- management interfaces live on `10.0.10.0/24`
- the Talos/Kubernetes service plane lives on `10.0.20.0/24`
- Home Assistant runs on `10.0.20.60`
- the SLZB-MR4U radio coordinator lives on `10.0.20.61`
- legacy VMs still consume `192.168.20.0/24`
- internal hostnames such as `argocd.local.jabbas.dev`,
  `grafana.local.jabbas.dev`, and `longhorn.local.jabbas.dev` resolve to
  `10.0.20.80` and are routed by Traefik

## Key Docs

- Cluster bootstrap:
  [`machines/stratton/k8s/setup.md`](machines/stratton/k8s/setup.md)
- Kubernetes workloads:
  [`machines/stratton/k8s/workloads/README.md`](machines/stratton/k8s/workloads/README.md)
- Home Assistant:
  [`machines/home-assistant/README.md`](machines/home-assistant/README.md)
- SLZB-MR4U coordinator:
  [`machines/slzb-mr4u/README.md`](machines/slzb-mr4u/README.md)
- TrueNAS note:
  [`machines/stratton/vms/truenas/README.md`](machines/stratton/vms/truenas/README.md)
