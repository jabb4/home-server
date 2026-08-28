# Recyclarr

Syncs TRaSH Guide quality profiles and custom formats into Sonarr and Radarr on
`apps-vm`. Runs in **cron mode**: the container stays up and triggers
`recyclarr sync` on `CRON_SCHEDULE` (currently `@weekly`).

Managed by Dockhand. Changes to `compose.yml` or `config/recyclarr.yml` land on
the host on the next Dockhand reconcile.

## Files

```text
compose.yml          # the stack
.env.example         # template for the per-host .env (Sonarr/Radarr URLs + API keys)
config/recyclarr.yml # TRaSH Guide selections (profiles, custom formats, etc.)
```

The Sonarr/Radarr URLs and API keys are referenced from `recyclarr.yml` via
`!env_var` tags. They're passed into the container through the `environment:`
block in `compose.yml`, which in turn reads them from a per-host `.env` file
sitting next to `compose.yml`.

## First-run setup on `apps-vm`

```bash
cd machines/stratton/vms/apps/docker-services/managed/recyclarr
cp .env.example .env
chmod 600 .env
# edit .env and fill in the real SONARR_API_KEY and RADARR_API_KEY
```

`.env` is gitignored, so the real keys never enter the repo and Dockhand only
ever syncs the tracked files.

## Ad-hoc operations

Cron mode does not block manual commands. Run them against the live container:

```bash
# Preview the next sync without writing anything
docker compose exec recyclarr recyclarr sync --preview

# Sync just one app
docker compose exec recyclarr recyclarr sync sonarr --log debug

# Re-sync immediately instead of waiting for the next weekly run
docker compose exec recyclarr recyclarr sync
```

## Change the schedule

Edit `CRON_SCHEDULE` in `compose.yml` (supports standard cron syntax and
shortcuts like `@daily`, `@weekly`, `@monthly`). Commit and push — Dockhand
applies it.

## Rollback

Stop the container locally on `apps-vm`:

```bash
docker compose down
```

The TRaSH Guide settings that were already pushed into Sonarr/Radarr remain;
Recyclarr only touches those instances when it actively runs a sync.
