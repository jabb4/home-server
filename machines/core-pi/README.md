# Core PI

Core PI is the Raspberry Pi 5 that runs the always-on control plane for the homelab.

Services:
- Traefik edge proxy (the single ingress for every `*.local.jabbas.dev` route)
- Dockhand GitOps controller for every Docker host
- Homepage dashboard on `homepage.local.jabbas.dev`

## Host setup

### Linux Distro
DietPI

### Enable memory cgroup (to be able to get RAM metrics in dockhand)

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
