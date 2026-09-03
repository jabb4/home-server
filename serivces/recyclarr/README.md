# Recyclarr

Syncs TRaSH Guide quality profiles and custom formats into Sonarr and Radarr. Runs in **cron mode**: the container stays up and triggers `recyclarr sync` on `CRON_SCHEDULE`.

Managed by Dockhand. Changes to `compose.yml` or `config/recyclarr.yml` land on
the host on the next Dockhand reconcile.

## Quality Profiles

One profile per app, **Best Available**, from the TRaSH profile *Remux 2160p (Combined)*
(`911df0e05a395c19d8b3efc76a7467c1` Sonarr, `d1d310673359205736b4b84acd5ea8c8` Radarr).

Order: `WEB 2160p > Bluray-2160p > Remux 2160p > Bluray-1080p > WEB 1080p` — 2160p when it exists, 1080p when it doesn't, no 720p or HDTV. The cutoff sits on the remux tier, so any 2160p file is final and remux is only ever a last resort.

Custom formats and scores come from the guides and re-sync every run; only the quality
order, cutoff and `preferred_ratio` are pinned in `config/recyclarr.yml`.

## Deployment
You should have Sonarr and Radarr deployed before you deploy recyclarr

Deployed through Dockhand, targeting Core PI. Secrets go in the per-stack
environment store in the Dockhand UI (Stack -> Environment Variables), not in
this repo. `.env.example` documents the keys.

Changes to `compose.yml` or anything in `config/` land on the host at the next
reconcile.


## Change the schedule

Edit `CRON_SCHEDULE` in `compose.yml` (supports standard cron syntax and
shortcuts like `@daily`, `@weekly`, `@monthly`). Commit and push — Dockhand
applies it.

## Rollback

Stop the stack from the Dockhand UI, or for emergency hand-recovery on Media PI:

```bash
docker compose down
```
