# Homepage

Homepage dashboard for the homelab. Runs on Core PI and is orchestrated by
Dockhand. Traefik publishes it at `https://homepage.local.jabbas.dev` and proxies
to `http://127.0.0.1:3001`.

The port is bound to loopback only, so unlike Dockhand there is no direct-IP
fallback — if Traefik is down, Homepage is unreachable. That is fine for a
dashboard.


## Config

`./config` is a relative bind mount, so the files in this directory are the live
config. Dockhand writes them to the host on reconcile and the container reads
them from there.

| File | Purpose |
| --- | --- |
| `settings.yaml` | Title, theme, and the declared weather providers |
| `services.yaml` | The service tiles, grouped by Infrastructure / Streaming / Home Automation |
| `bookmarks.yaml` | Static links — no secrets, no widgets |
| `widgets.yaml` | Header widgets (search, datetime) |
| `docker.yaml` | Empty — the Docker socket is not mounted, so there is no container integration |
| `proxmox.yaml` | Empty — no Proxmox integration |
| `custom.css`, `custom.js` | Empty placeholders |


## Deployment

Deployed through Dockhand, targeting Core PI. Secrets go in the per-stack
environment store in the Dockhand UI (Stack -> Environment Variables), not in
this repo. `.env.example` documents the keys.

Changes to `compose.yml` or anything in `config/` land on the host at the next
reconcile.


## Security

Homepage has no built-in authentication. Anything that can reach
`homepage.local.jabbas.dev` sees the full dashboard, including the bookmarks.
Put Authentik forward auth in front of it once that is set up.


## Update

The image tag is pinned, so Renovate opens a PR when a new version ships. Merge
it and Dockhand applies it on the next reconcile — no manual step on the host,
unlike the bootstrap stacks.

To roll back, set the previous tag in `compose.yml` and let it reconcile again.
