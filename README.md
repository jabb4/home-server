# Homelab Architecture

## Rocky (Pi 5)
### Description
- Handels DNS

### Host OS
- **DietPi**

### Services
- Pi-Hole
- Unbound



## Jordan (Pi 4)
### Description
- IP-KVM for Stratton. Lets me control it over the network. Even features like turn on/off and change bios.

### Host OS
- **PiKVM**

### Services
- PiKVM



## Stratton (4u Server)
### Description
- Main server for most services

### Host OS
- **Proxmox VE**

---

### Services
- Node Exporter

---

### VMs & Containers

#### 1. TrueNAS
- **ID**: 101
- **Type**: Full VM
- **Startup priority**: 1
- **Specs**: 4 vCPU / 32GB RAM / 32GB Boot
- **Extra**: SATA passthrough (4 * 4TB HDD drives)
- **Host OS**: TrueNAS (Previously TrueNAS Scale)
- **Services**:
  - TrueNAS

---

#### 2. Home Assistant
- **ID**: 104
- **Type**: Full VM
- **Startup priority**: None
- **Specs**: 2 vCPU / 4GB RAM / 32GB boot
- **Extra**: USB passthrough (Zigbee dongle)
- **Host OS**: Home Assistant OS
- **Services**:
  - Home Assistant

---

#### 3. Infrastructure
- **ID**: 100
- **Type**: Full VM
- **Startup priority**: 2
- **Specs**: 4 vCPU / 12GB RAM / 48GB boot
- **Extra**: None
- **Host OS**: NixOS + Docker containers
- **Services**:
  - Traefik
  - Crowdsec
  - Authentik
  - Uptime Kuma
  - Grafana
  - Prometheus

---

#### 4. Apps
- **ID**: 103
- **Type**: Full VM
- **Startup priority**: None
- **Specs**: 6 vCPU / 12GB RAM / 80GB boot
- **Extra**: Mount SMB shares
- **Host OS**: NixOS + Docker containers
- **Services**:
  - Homepage
  - Nextcloud
  - Immich
  - Paperless-NGX
  - Open-WebUI
  - SearxNG
  - Vaultwarden

---

#### 6. Media Downloader
- **ID**: 106
- **Type**: Full VM
- **Startup priority**: None
- **Specs**: 2 vCPU / 4GB RAM / 32GB boot
- **Extra**: Mount SMB shares
- **Host OS**: NixOS + Docker containers
- **Services**:
  - Gluten
  - Jellyseerr
  - SABnzbd
  - Radarr
  - Sonarr
  - Prowlarr
  - Bazarr

---

#### 7. GPU Workloads
- **ID**: 105
- **Type**: Full VM
- **Startup priority**: None
- **Specs**: 8 vCPU / 32GB RAM / 400GB boot
- **Extra**: GPU passthrough, Mount SMB shares
- **Host OS**: NixOS + Docker containers
- **Services**:
  - Jellyfin
  - Ollama
  - ComfyUI
  - Node Exporter (dcgm-exporter)

---

#### 8. DMZ (External Entry Point)
- **ID**: 102
- **Type**: Full VM
- **Startup priority**: None
- **Specs**: 1 vCPU / 2GB RAM / 16GB boot
- **Host OS**: NixOS + Docker containers
- **Services**:
  - Cloudflared (Cloudflare Tunnel)
  - Tailscale Agent