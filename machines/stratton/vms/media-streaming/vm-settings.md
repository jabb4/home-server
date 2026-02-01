# Proxmox VM settings:

## General
- VM ID: 105
- Name: GPU-Workloads
- Start at boot: Checked
- Advanced: Checked

## OS
- ISO image: nixos-minimal

## System
- Machine: q35
- BIOS: OVMF 
- EFI Storage: VM-storage
- Pre-Enroll keys: Unchecked
- Qemu Agent: Checked

## Disks
- Storage: VM-storage
- Disk size: 400 GB
- Discard: Checked
- SSD emulation: Checked

## CPU
- Cores: 8

## Memory
- 32768 MiB
- Ballooning Device: Un-checked
  
## PCI Device (Add when vm created)
- Raw Device: RTX 4060Ti
- All Functions: Checked