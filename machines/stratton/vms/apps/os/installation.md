# Installation of the VM os

1. Download and NixOS Minimal ISO image from https://nixos.org/download/

2. Create the VM with the disiered settings in Proxmox and select the NixOS iso

3. Install Nix configs with:
````bash
git clone https://your-repo
cd your-repo
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --yes-wipe-all-disks disk-config.nix
nix-collect-garbage -d
sudo nixos-install --flake .#apps
````

4. Shutdown and unmount iso