# Media downloader

Downloads movies and tv series trough usenet.

Managed by Dockhand. Changes to `compose.yml` land on the host on the next Dockhand reconcile.


## Deployment
Deployed through Dockhand, targeting Media PI. Secrets go in the per-stack
environment store in the Dockhand UI (Stack -> Environment Variables), not in
this repo. `.env.example` documents the keys.

Changes to `compose.yml` land on the host at the next reconcile.


## Networking — which URL to use where

SABnzbd, Prowlarr, Radarr, Sonarr and Bazarr all run with `network_mode: "service:gluetun"`, so they
share one network namespace. **They reach each other on `localhost`**, and only gluetun publishes
ports. Seerr is not in that namespace — it has its own `ports:` — so it must use the host IP.

| From | To | URL |
| --- | --- | --- |
| Radarr, Sonarr | SABnzbd | host `localhost`, port `8080` |
| Prowlarr | Radarr / Sonarr | `http://localhost:7878` / `http://localhost:8989` |
| Prowlarr | itself ("Prowlarr Server") | `http://localhost:9696` |
| Bazarr | Radarr / Sonarr | `http://localhost:7878` / `http://localhost:8989` |
| Seerr | Radarr / Sonarr | `http://10.0.20.80:7878` / `http://10.0.20.80:8989` |
| Recyclarr | Sonarr / Radarr | `SONARR_URL` / `RADARR_URL` in `.env` |

Seerr and Recyclarr are in the stack but outside the gluetun namespace, so `localhost` does not reach
the *arrs from either of them.

Using a `*.local.jabbas.dev` hostname between two containers that share the gluetun namespace still
works, but it hairpins out to Core PI Traefik and back, and it breaks whenever Traefik is down.
Prefer `localhost`.


## Rollback

Stop the stack from the Dockhand UI, or for emergency hand-recovery on Media PI:

```bash
docker compose down
```
