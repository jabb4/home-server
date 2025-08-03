# Installation of the VM os

1. Download and NixOS Minimal ISO image from https://nixos.org/download/

2. Create the VM with the disiered settings in Proxmox and select the NixOS iso

3. Install Nix configs with:
````bash
git clone https://your-repo
cd your-repo
nix-shell -p nixFlakes # Enables flakes
nix run .#disko-install # Partitions disk
nixos-install --flake .#vm # Installs the system
````

4. Shutdown and unmount iso