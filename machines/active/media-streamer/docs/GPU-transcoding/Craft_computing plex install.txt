-Plex Install (Debian Linux)-

echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -

sudo apt update

sudo apt install plexmediaserver


-Configure Network Share for Plex Media-

sudo mkdir /PlexMedia

sudo nano /etc/fstab

Add to bottom of file
//PATH-TO-FILE-SERVER /PlexMedia cifs username=$$$$$$$$,password=######## 0 0

Save file and exit

Reboot

cd /PlexMedia

Verify files from your file server are showing up here


-Virtual Machine PCIe passthrough (Debian Linux)-

-Confirm GPU is being passed through-

lspci


-Download nVidia Drivers-

Visit nVidia.com/drivers, locate your card, and find out what the most recent version is

wget https://international.download.nvidia.com/XFree86/Linux-x86_64/###.##.##/NVIDIA-Linux-x86_64-###.##.##.run

sudo chmod +x NVIDIA-Linux-x86_64-###.##.##.run


-Disable Nouveau drivers in kernel-

sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sudo bash -c "echo options nouveau modset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"

sudo update-initramfs -u


--REBOOT--


-Confirm no drivers running for nVidia GPU-

lspci -v

Find GPU. There should be no 'Kernel driver in use:' line


-Install nVidia Drivers-

sudo apt update
sudo apt install build-essential libglvnd-dev pkg-config

./NVIDIA-Linux-x86_64-###.##.##.run

Complete prompts to install

lspci -v

Confirm GPU is using  nvidia drivers

"Kernel driver in use: nvidia"

nvidia-smi

Confirm card is seen and active. If your receive "Unknown Error", follow next step on ProxMox host ->


-Hide VM identifiers from nVidia-

SSH into ProxMox

cd /etc/pve/qemu-server

nano ###.conf (# is the VM identifier of your Plex server)

Modify cpu line...

cpu: host,hidden=1

Save file and exit.

Start Plex VM.

nvidia-smi to confirm GPU is working