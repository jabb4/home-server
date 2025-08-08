# Proxmox VM settings:

## General
- VM ID: 100
- Name: Infrastructure
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
- Disk size: 48
- Discard: Checked
- SSD emulation: Checked

## CPU
- Cores: 4

## Memory
- 12288 MiB