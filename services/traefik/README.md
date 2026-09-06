# Traefik

Single edge proxy for the homelab. Runs on Core PI and fronts every
`*.local.jabbas.dev` route, regardless of which host the backend lives on.

`*.local.jabbas.dev` resolves through a wildcard DNS record on the UniFi gateway
pointing at Core PI (`10.0.20.53`). Every name in the routes table lands on this
Traefik.


## Deployment

Deployed through Dockhand, targeting Core PI. Secrets go in the per-stack
environment store in the Dockhand UI (Stack -> Environment Variables), not in
this repo. `.env.example` documents the keys.

Changes to `compose.yml` or anything in `config/` land on the host at the next
reconcile.


## Reconcile

Register the stack in Dockhand pointing at this directory; Dockhand handles
`compose up -d` on Core PI and re-reconciles on every git push. Traefik's file
provider hot-reloads `dynamic.yml`, so route-only changes apply without a
container restart.

Traefik uses Cloudflare DNS-01 to request a wildcard certificate for
`local.jabbas.dev` and `*.local.jabbas.dev`. The ACME account and certificates
are stored in the `traefik_letsencrypt` Docker volume at `/letsencrypt/acme.json`.


## Rollback

Stop the stack from the Dockhand UI, or for emergency hand-recovery on Core PI:

```bash
docker compose down
```

`traefik_letsencrypt` is untouched by `down`, so bringing the stack back up
reuses the existing certificate instead of re-issuing it.
