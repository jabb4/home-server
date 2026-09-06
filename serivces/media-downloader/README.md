# Media downloader

Downloads movies and tv series trough usenet.

Managed by Dockhand. Changes to `compose.yml` land on the host on the next Dockhand reconcile.


## Deployment
Deployed through Dockhand, targeting Media PI. Secrets go in the per-stack
environment store in the Dockhand UI (Stack -> Environment Variables), not in
this repo. `.env.example` documents the keys.

Changes to `compose.yml` land on the host at the next reconcile.


## Rollback

Stop the stack from the Dockhand UI, or for emergency hand-recovery on Media PI:

```bash
docker compose down
```
