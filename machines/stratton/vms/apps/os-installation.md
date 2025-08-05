# Installation of the VM os

1. Download and NixOS Minimal ISO image from https://nixos.org/download/

2. Create the VM with the disiered settings in Proxmox and select the NixOS iso

3. Install Nix configs with:
````bash
# In proxmox console
passwd #Change password so you can SSH
ip a # Get ip address

# SSH into the vm and continue
git clone https://github.com/jabb4/home-server.git
cd home-server/nixos
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount --yes-wipe-all-disks hosts/apps/disk-config.nix
nix-collect-garbage -d
sudo nixos-install --no-root-passwd --flake .#apps
````

1. Shutdown and unmount iso