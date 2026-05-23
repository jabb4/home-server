# Rocky

Rocky is the Raspberry Pi 5 that runs the always-on control plane for the
homelab.

Services:

- Pi-hole DNS on `10.0.20.53`
- Traefik edge proxy (the single ingress for every `*.local.jabbas.dev` route)
- Dockhand GitOps controller for every Docker host
- Homepage dashboard on `homepage.local.jabbas.dev`

Service docs:

- [`docker-services/dockhand/README.md`](docker-services/dockhand/README.md)
- [`docker-services/pi-hole/README.md`](docker-services/pi-hole/README.md)
- [`docker-services/managed/traefik/README.md`](docker-services/managed/traefik/README.md)
- [`docker-services/managed/homepage/README.md`](docker-services/managed/homepage/README.md)

`dockhand` and `pi-hole` live outside `managed/` and are brought up by hand on
Rocky — not reconciled by Dockhand, since a bad reconcile to either would
break the GitOps control plane itself (repo pull or DNS). Everything else
under `managed/` is Dockhand-reconciled, including Traefik: Dockhand is
published on Rocky's LAN IP (`http://10.0.20.53:3000`) as a non-Traefik
fallback, so a broken Traefik no longer locks the control plane out.

## Host setup

### Enable memory cgroup

So you can see memory usage in Dockhand.

1. Append `cgroup_memory=1` to the single line in
   `/boot/firmware/cmdline.txt`:

   ```bash
   sudo sed -i 's/$/ cgroup_memory=1/' /boot/firmware/cmdline.txt
   ```
2. Check that `/boot/firmware/cmdline.txt` includes both `cgroup_enable=memory` and `cgroup_memory=1` (only one line)

3. `sudo reboot`. Can take ~5 min to get everything back up.

4. Confirm with `cat /sys/fs/cgroup/cgroup.controllers` — should include
   `memory`.
