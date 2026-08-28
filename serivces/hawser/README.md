# Hawser

Hawser is the Dockhand agent that exposes apps-vm's Docker daemon to the
GitOps controller on Rocky. With this running, Dockhand can reconcile the
`managed/` stacks on apps-vm (jellyfin, media-downloader, recyclarr) the same
way it does for Rocky's own stacks.

Runs in **edge mode**: the agent dials Dockhand outbound over WebSocket, so
apps-vm needs no inbound firewall rule.

## Prerequisites

- Dockhand reachable at `https://dockhand.local.jabbas.dev` from apps-vm
- A pairing token from Dockhand (generated in step 1 below).
- `/var/lib/hawser/stacks` exists on the host. Hawser writes the compose
  files Dockhand sends here, and `docker compose` runs from this directory
  so relative bind mounts in the managed stacks resolve correctly.

## Start

1. In the Dockhand UI: Settings -> Environments -> Add -> Hawser Edge.
   Name it `apps-vm`. Copy the generated token (shown once).
2. On apps-vm:

   ```bash
   sudo mkdir -p /var/lib/hawser/stacks
   cp .env.example .env
   # paste the token into HAWSER_TOKEN
   sudo docker compose config
   sudo docker compose up -d
   sudo docker compose logs -f hawser
   ```

3. Back in Dockhand, the `apps-vm` environment should flip to connected.
   Use the Test button to confirm.

## Adding the managed stacks to Dockhand

Once the environment is connected, register each existing stack in the
Dockhand UI, pointing at its path in this repo and targeting the `apps-vm`
environment:

- `machines/stratton/vms/apps/docker-services/managed/jellyfin`
- `machines/stratton/vms/apps/docker-services/managed/media-downloader`
- `machines/stratton/vms/apps/docker-services/managed/recyclarr`

For each one, before letting Dockhand bring it up:

1. `docker compose down` the existing hand-managed instance on apps-vm so the
   two reconcilers don't fight over the same containers.
2. Move the contents of the on-host `.env` into Dockhand's per-stack env
   store (Stack -> Environment Variables). The repo's `.env.example` files
   document the keys.
3. Verify Dockhand reuses the existing named volumes (`docker volume ls`
   before/after); the compose project name must match the stack name in
   Dockhand for volumes to re-attach.
