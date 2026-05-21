# Dockhand

Dockhand is the GitOps controller for every Docker host in the homelab. It pulls
Compose stacks from this repository and reconciles them on the hosts it manages.

- UI: `https://dockhand.local.jabbas.dev` (proxied by Rocky Traefik)
- Container port: `127.0.0.1:3000` (loopback only — Traefik on Rocky is the
  only path in, since Dockhand holds the Docker socket and Git credentials)
- State: Docker volume `dockhand_data` mounted at `/app/data` (DATA_DIR) — holds
  SQLite, config, and cloned git checkouts (`/app/data/git-repos/`)

This stack sits at `machines/rocky/docker-services/dockhand/`, not under
`docker-services/managed/`, because Dockhand cannot reconcile itself: bringing
it up has to happen by hand on Rocky before any GitOps loop exists. The same
applies to `pi-hole/` and `traefik/` next to it — those are the other two
stacks the control plane depends on and the only other ones outside `managed/`.

## Why on Rocky

Rocky is always on, sits on the management/services VLAN, and already runs the
edge proxy. Putting Dockhand here keeps the GitOps control plane available even
when Stratton is powered off.

## Hosts managed by Dockhand

- Rocky itself, via the mounted `/var/run/docker.sock`.
- `apps-vm` (Stratton, `192.168.20.103`), reached over TCP+TLS or via the Hawser
  agent. Pick one model in the Dockhand UI when registering the host.

## Start

```bash
docker compose config
docker compose up -d
docker compose logs -f dockhand
```

The UI binds to `127.0.0.1:3000` only. Reach it through Rocky Traefik at
`https://dockhand.local.jabbas.dev`.

## First-run configuration

In the UI:

1. Create an admin account.
2. Add this git repository as a source. Point it at the directory containing the
   compose file for each stack (e.g.
   `machines/rocky/docker-services/managed/homepage`).
   Do not add the `dockhand/`, `pi-hole/`, or `traefik/` directories — those
   stacks are bootstrap and stay outside Dockhand's reconciliation loop.
3. Register the remote Docker host `apps-vm`.
4. Create one stack per service, choosing the right host and the right compose
   path in the repo.

Keep secrets in the per-stack `.env` managed inside Dockhand, not in this repo.

## Rollback

```bash
docker compose down
```

The Dockhand volumes are preserved on disk, so reinstalling with the same
volumes restores all configured sources, hosts, and stacks.
