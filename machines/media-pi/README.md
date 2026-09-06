# Media PI

Media PI is the Raspberry Pi 5 that runs the streaming and download stacks. It is a Dockhand-managed
Docker host — see [`services/dockhand/README.md`](../../services/dockhand/README.md).

Services:
- Jellyfin on `jellyfin.local.jabbas.dev`
- Gluetun + SABnzbd, Prowlarr, Radarr, Sonarr, Bazarr
- Seerr on `seerr.local.jabbas.dev`
- Recyclarr (cron, no UI)

## Network

- IP: `10.0.20.80`
- Subnet: `10.0.20.0/24`
- Gateway: `10.0.20.1`
- Network role: Infra VLAN
- Media library source: UNAS Pro at `10.0.20.20`, same VLAN, so NFS needs no inter-VLAN rule


## Storage layout

`/mnt/data` is the local m.2 SSD. Only `/mnt/data/media` is the NFS mount from the UNAS Pro.

```text
/mnt/data/                 local m.2 SSD, owned 1000:1000
├── usenet/                SABnzbd working set — local, fast, disposable
│   ├── incomplete/
│   └── complete/
│       ├── movies/
│       └── tv/
└── media/          <───── NFS mount from 10.0.20.20 (UNAS Pro)
    ├── movies/
    └── tv/
```

Follows the [TRaSH file and folder structure](https://trash-guides.info/File-and-Folder-Structure/),
pruned to the two categories this stack uses. The paths are not a free choice — they are what the
compose files bind-mount.

Downloads stay local because this stack is usenet-only: nothing seeds, so hardlinks buy nothing, and
keeping par2 repair and unrar on the NVMe means only the finished file crosses the network. The
trade-off is that `usenet/` and `media/` are different filesystems, so **Sonarr/Radarr imports are
copy + delete, not hardlink** — leave "Use Hardlinks instead of Copy" off. Imports take as long as a
network copy and briefly need the space twice.

---

## Host setup

### 1. Flash and first boot

1. Use Raspberry Pi Imager to flash DietPi onto the m.2 SSD. It is under `Other general-purpose OS`.
3. Boot and wait — the first boot resizes the filesystem and can take several minutes.
5. SSH in as `root` / `dietpi`, let it update, and set both passwords.

### 2. OS setup

1. `dietpi-config` — hostname `media-pi`, timezone `Europe/Stockholm`, locale.
2. Enable the memory cgroup so Dockhand reports RAM. The kernel needs **both** flags —
   `cgroup_memory=1` on its own does nothing, `cgroup_enable=memory` is what turns the controller on:

   ```bash
   grep -q cgroup_enable=memory /boot/firmware/cmdline.txt || sudo sed -i 's/$/ cgroup_enable=memory/' /boot/firmware/cmdline.txt
   grep -q cgroup_memory=1 /boot/firmware/cmdline.txt || sudo sed -i 's/$/ cgroup_memory=1/' /boot/firmware/cmdline.txt
   cat /boot/firmware/cmdline.txt   # must still be exactly one line
   sudo reboot
   ```

   Verify after the reboot:

   ```bash
   cat /proc/cmdline                       # both flags present, no `cgroup_disable=memory`
   cat /sys/fs/cgroup/cgroup.controllers   # must list `memory`
   ```

   If `/proc/cmdline` still shows `cgroup_disable=memory`, it is baked into the bootargs of
   `/boot/firmware/bcm2712-rpi-5-b.dtb` and wins over the cmdline flag — remove it there.

   Same step as Core PI — rationale in [`machines/core-pi/README.md`](../core-pi/README.md).
3. Install Docker, the Compose plugin, and the NFS client. DietPi has no NFS-client software entry, so
   `nfs-common` comes from apt:

   ```bash
   sudo dietpi-software install 162 134   # 162 = Docker, 134 = Docker Compose
   sudo apt install -y nfs-common
   ```

   If DietPi deselects Docker complaining about missing kernel modules, reboot and re-run. That is the
   expected behaviour right after a kernel upgrade.
4. Confirm the UID matches the `PUID`/`PGID` in the compose files:

   ```bash
   id dietpi   # expect uid=1000 gid=1000
   ```

### 3. Export the library from the UNAS Pro

On the UNAS Pro at `10.0.20.20`:

1. UniFi Drive → Settings → Services → enable NFS.
2. On the media Shared Drive, set the squash mode to **Collaborative Mode (All Squash)**.
   Do not pick Isolated Mode: it cannot be reverted and it disables SMB and Drive UI access for that
   share. The media library needs neither root nor client-side `chown`.
3. Add `10.0.20.80` to that share's allowed-clients list. A missing entry is the usual cause of
   `mount.nfs: access denied by server while mounting`.
4. The share is named `MediaLibrary`, so the export path is
   `10.0.20.20:/var/nfs/shared/MediaLibrary`. Confirm it from the Pi before editing `/etc/fstab`:

   ```bash
   sudo showmount -e 10.0.20.20
   ```

### 4. Folder structure and NFS mount

1. Create the local tree and chown it **before** mounting, so `chown -R` never reaches the NAS:

   ```bash
   sudo mkdir -p /mnt/data/usenet/{incomplete,complete/{movies,tv}} /mnt/data/media
   sudo chown -R 1000:1000 /mnt/data
   ```

2. Append to `/etc/fstab`:

   ```text
   10.0.20.20:/var/nfs/shared/MediaLibrary  /mnt/data/media  nfs  _netdev,nofail,hard,noatime,x-systemd.mount-timeout=30  0  0
   ```

   - `hard` — a NAS hiccup blocks I/O instead of returning errors mid-write.
   - `nofail` and `x-systemd.mount-timeout=30` — the Pi still boots and stays reachable over SSH if the
     UNAS is down.
   - No `nfsvers=`, so the client negotiates. Check the result with `findmnt /mnt/data/media` and only
     pin `nfsvers=3,nolock` if v4 misbehaves.
   - Deliberately not `x-systemd.automount`: gating Docker (step 4) needs a real boot-time mount unit.

3. Mount it and create the library folders on the NAS:

   ```bash
   sudo systemctl daemon-reload
   sudo mount -a
   sudo mkdir -p /mnt/data/media/{movies,tv}
   touch /mnt/data/media/.write-test && rm /mnt/data/media/.write-test
   ```

   `ls -ln /mnt/data/media` shows the UNAS anonymous UID rather than `1000`. That is All Squash working
   as intended, not a misconfiguration.

4. Stop Docker from starting without the library. Without this, the *arrs would write into the bare
   mountpoint on the SSD and that data would vanish under the mount when NFS came back.

   ```bash
   sudo systemctl edit docker.service
   ```

   `systemctl edit` creates `/etc/systemd/system/docker.service.d/override.conf` and reloads systemd
   on save, so there is no directory to create by hand and no separate `daemon-reload`. It opens an
   editor with two markers — the text goes in the blank lines **between** them:

   ```text
   ### Editing /etc/systemd/system/docker.service.d/override.conf
   ### Anything between here and the comment below will become the contents of the drop-in file

   [Unit]
   RequiresMountsFor=/mnt/data/media

   ### Edits below this comment will be discarded
   ```

   Everything below the second marker is the vendor unit shown commented-out for reference. Anything
   written down there is thrown away. DietPi already ships its own drop-in
   (`dietpi-simple.conf`); this one stacks alongside it rather than replacing it.

   Confirm systemd actually turned the directive into a live dependency — not just that the file
   exists:

   ```bash
   systemctl show docker.service -p Requires -p After | grep -o mnt-data-media.mount
   ```

   Printing `mnt-data-media.mount` means the gate is armed. Printing nothing means the unit name does
   not match the mount path and the gate is silently doing nothing.

   The boot itself is deliberately *not* blocked on the mount — that is what `nofail` in the fstab
   line buys. A failed `remote-fs.target` on a headless Pi can drop it to an emergency shell with no
   network, so a NAS that boots slower than the Pi after a power cut would need a keyboard at the
   rack. Gating Docker gives the same protection and leaves SSH working.

   Docker is socket-activated (`Requires=docker.socket` in the vendor unit), so with the library
   missing the failure can surface as an error from whatever touched `/var/run/docker.sock` rather
   than at `systemctl start docker`. Either way no container starts — that is the gate working, not a
   broken one.

   After a NAS outage the mount does not retry on its own:

   ```bash
   sudo systemctl start mnt-data-media.mount
   sudo systemctl start docker
   ```

### 5. Join the GitOps loop

Follow [`services/hawser/README.md`](../../services/hawser/README.md), naming the agent `media-pi`.

Then create the stacks in Dockhand against the `media-pi` environment, in this order:

1. `services/jellyfin`
2. `services/media-downloader` — the whole download stack including Recyclarr. VPN keys and the
   pinned Radarr/Sonarr API keys go in the per-stack environment store in the Dockhand UI, per its
   `.env.example`

### 6. First-run app config

Run these in order:

1. [SABnzbd](../../services/media-downloader/docs/sabnzbd-setup.md)
2. [Prowlarr](../../services/media-downloader/docs/prowlarr-setup.md)
3. [Radarr, Sonarr and Recyclarr](../../services/media-downloader/docs/radarr-sonarr-recyclarr-setup.md)
4. [Jellyfin](../../services/jellyfin/README.md)
5. [Seerr](../../services/media-downloader/docs/seerr-setup.md)

---

## Verify

```bash
findmnt /mnt/data/media          # mounted from 10.0.20.20
df -h /mnt/data /mnt/data/media  # two filesystems, NAS capacity on the second
sudo reboot                      # then: docker ps — everything back up on its own
```

Check the failure path too — Docker must refuse to start with the library missing:

```bash
sudo systemctl stop docker
sudo umount /mnt/data/media
sudo systemctl start docker      # expected to fail
sudo mount -a && sudo systemctl start docker
```

Then end to end: request a title in Seerr, watch Radarr grab it, SABnzbd download into
`/mnt/data/usenet`, the import land in `/mnt/data/media/movies`, and the file play in Jellyfin.

## Reference

- [DietPi installation](https://dietpi.com/docs/install/)
- [Accessing UniFi Drive from Linux using NFS](https://help.ui.com/hc/en-us/articles/26277250895895-Accessing-Your-UniFi-Drive-from-Linux-Desktop-Using-NFS)
- [TRaSH file and folder structure](https://trash-guides.info/File-and-Folder-Structure/)
- [Raspberry Pi bootloader configuration](https://www.raspberrypi.com/documentation/computers/raspberry-pi.html)
