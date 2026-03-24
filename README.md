# Homelab Architecture

This repository documents the current and target architecture for the home lab running on `Stratton`.

The main goals are:

- separate management traffic from service traffic
- move `infrastructure-vm` and `apps-vm` into a Talos-based Kubernetes cluster
- keep storage, edge access, and hardware-specific workloads outside the cluster where that is simpler and safer

## Network Layout

| Network | VLAN | Subnet | Purpose | Notes |
| --- | --- | --- | --- | --- |
| Default LAN | default | `192.168.10.0/24` | user devices and admin workstation | admin clients originate access to management and service networks |
| Management | `10` | `10.0.10.0/24` | admin-only interfaces | Proxmox, TrueNAS, PiKVM, switch/AP management, NUT |
| Services | `20` | `10.0.20.0/24` | cluster nodes and internal services | Talos nodes, Kubernetes API, ingress, internal service IPs |
| DMZ Edge | `30` | `10.0.30.0/24` | external entry points | optional dedicated network for Cloudflared and Tailscale |
| Legacy Server Network | legacy | `192.168.20.0/24` | existing VM IP space during migration | retired after services are moved to Kubernetes or new VLANs |

## Address Plan

### Management (`10.0.10.0/24`)

| IP / Range | Use |
| --- | --- |
| `10.0.10.1` | UDM SE gateway / DHCP server |
| `10.0.10.10` | Stratton Proxmox management |
| `10.0.10.11` | TrueNAS management |
| `10.0.10.12` | Jordan / PiKVM |
| `10.0.10.13` | NUT |
| `10.0.10.200-10.0.10.254` | DHCP pool for temporary devices |

### Services (`10.0.20.0/24`)

| IP / Range | Use |
| --- | --- |
| `10.0.20.1` | UDM SE gateway / DHCP server |
| `10.0.20.10` | Kubernetes API VIP |
| `10.0.20.11` | `cp-1` Talos control plane |
| `10.0.20.21` | `worker-1` Talos worker |
| `10.0.20.53` | Rocky DNS services (`Pi-hole` / `Unbound`) |
| `10.0.20.200-10.0.20.254` | DHCP pool for temporary devices |

### DMZ Edge (`10.0.30.0/24`)

| IP / Range | Use |
| --- | --- |
| `10.0.30.1` | UDM SE gateway |
| `10.0.30.10` | DMZ VM |
| `10.0.30.200-10.0.30.254` | DHCP pool for temporary devices |

## Traffic Model

- `Management` is for admin interfaces only.
- `Services` is for Kubernetes nodes, ingress, and service endpoints.
- `Default LAN` can reach `Management` only for administration.
- `Services` should not initiate connections into `Management` unless explicitly required.
- `DMZ Edge` should only reach the published ingress endpoints it needs.
- Talos API and the Kubernetes API must not be exposed broadly across the LAN.

## Core Machines

### Rocky (Pi 5)

- Role: DNS
- Services: `Pi-hole`, `Unbound`
- Target network: `Services`

### Jordan (Pi 4)

- Role: out-of-band access
- Services: `PiKVM`
- Target network: `Management`

### NUT (Pi 3b+)

- Role: UPS monitoring and safe shutdown
- Services: `NUT`
- Target network: `Management`

### Stratton (4U Server)

- Role: main virtualization host
- Host OS: `Proxmox VE`
- Target network: `Management`

### Dedicated workloads on Stratton

| Workload | State | Notes |
| --- | --- | --- |
| `TrueNAS` | stays outside Kubernetes | storage remains a dedicated VM |
| `Home Assistant` | stays outside Kubernetes | hardware integration stays simpler in a dedicated VM |
| `DMZ VM` | stays outside Kubernetes initially | runs `Cloudflared` and `Tailscale` |
| `GPU Workloads VM` | stays outside Kubernetes initially | GPU passthrough and media/AI workloads remain separate for now |
| `Media Downloader VM` | stays outside Kubernetes initially | can be revisited later if needed |

## Kubernetes Cluster

Cluster bootstrap is managed from [machines/stratton/k8s/justfile](/Users/jacob/Projects/home-server/machines/stratton/k8s/justfile).

### Stack

- `Talos Linux`
- `Kubernetes`
- `Cilium`
- `Argo CD`
- `Longhorn`
- `Traefik`

### Nodes

| Node | Role | Network | IP |
| --- | --- | --- | --- |
| `cp-1` | control plane | `Services` | `10.0.20.11` |
| `worker-1` | worker | `Services` | `10.0.20.21` |
| `kubernetes-api` | API VIP | `Services` | `10.0.20.10` |

### Initial cluster model

- one dedicated control plane
- one worker node for all workloads
- no workload scheduling on the control plane
- future expansion can add more workers and split by trust level if needed

### Storage model

- `TrueNAS` remains outside Kubernetes and owns large shared NFS datasets
- `Longhorn` provides durable in-cluster app state on worker-local disks
- app configs, SQLite, and shared databases should use `Longhorn`
- large media/document libraries should use static `TrueNAS NFS` shares
- workers are expected to carry dedicated Longhorn disks and are labeled for
  Longhorn storage during bootstrap and worker join
- control planes do not participate in Longhorn storage

### Target security baseline

- separate namespaces for infra and apps, plus dedicated cluster-core namespaces
- default-deny `Cilium NetworkPolicy`
- `Pod Security Admission` at `restricted` for user workloads
- dedicated service accounts and least-privilege RBAC
- no `privileged`, `hostNetwork`, or `hostPath` unless there is a clear operational reason
- encrypted or externally managed secrets, not plain Kubernetes secrets committed to Git

## Service Placement

### Cluster Core

- `Cilium`
- `Argo CD`
- `Longhorn`

### Infra namespace

- `cert-manager`
- `Traefik`
- `CrowdSec`

- `Uptime Kuma`
- shared databases and backing services

### Apps namespace

- `Homepage`


### Outside Kubernetes for now
- `Authentik`
- `Prometheus`
- `Grafana`
- `Immich`
- `Paperless-NGX`
- `Vaultwarden`
- `Gitea`
- `Open-WebUI`
- `SearxNG`
- `MicroBin`
- `Cloudflared`
- `Tailscale`
- `TrueNAS`
- `Home Assistant`
- `Jellyfin`
- `Ollama`
- `ComfyUI`
- media downloader stack (`Jellyseerr`, `SABnzbd`, `Radarr`, `Sonarr`, `Prowlarr`, `Bazarr`)
