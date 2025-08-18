Run this after install.
[Proxmox VE Helper-Scripts](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install)


## PCI Passtrough

Proxmox pci passthrough:
https://pve.proxmox.com/wiki/PCI_Passthrough

Steps:
- Part1
1. First ennable IOMMU in bios.

2. check in proxmox that IOMMU is enbalbed
`dmesg | grep -e DMAR -e IOMMU` Should give "DMAR: IOMMU enabled" If there is no output, something is wrong.

3. block the GPU in proxmox: (this is for nvidia):
`echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf `
`echo "blacklist nvidia*" >> /etc/modprobe.d/blacklist.conf`