Run this after install.
[Proxmox VE Helper-Scripts](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install)


## PCI Passtrough

Proxmox pci passthrough:
https://pve.proxmox.com/wiki/PCI_Passthrough

Steps:
- Part1
1. First ennable IOMMU in bios.

2. check in proxmox that IOMMU is enbalbed
`dmesg | grep -e DMAR -e IOMMU` Should give "AMD-Vi: IOMMU performance counters supported" "Detected AMD IOMMU #0 (2 banks, 4 counters/bank)" or "DMAR: IOMMU enabled" If there is no output, something is wrong.

1. block the GPU in proxmox: (this is for nvidia):
`echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf `
`echo "blacklist nvidia*" >> /etc/modprobe.d/blacklist.conf`