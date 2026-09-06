# Dockhand

Dockhand is the GitOps controller for every Docker host in the homelab. It pulls
Compose stacks from this repository and reconciles them on the hosts it manages.

- Runs on: Core PI (`10.0.20.53`, DietPi)
- UI: `https://dockhand.local.jabbas.dev` (proxied by Traefik on the same Pi)
- Direct fallback: `http://10.0.20.53:3000` — published on the LAN so the control
  plane stays reachable when Traefik is down.

Dockhand cannot reconcile itself, so this stack is brought up by hand on Core PI
and stays outside the GitOps loop.


## Hosts managed by Dockhand

- Core PI itself, via the mounted `/var/run/docker.sock`.
- Media PI (`10.0.20.80`), reached through the Hawser agent — see
  [`../hawser/`](../hawser/).


## Encryption key

`ENCRYPTION_KEY` encrypts git credentials, registry passwords, OIDC secrets and
stack secrets. Left unset, Dockhand generates one into `.encryption_key` inside
the data dir; lose that file and the credentials are unrecoverable. Setting it
explicitly moves the key out of the data dir — Dockhand deletes the disk copy on
first start once the variable is present.

- New install: `openssl rand -base64 32`
- Existing install: extract the current key, do **not** generate a new one, or
  everything already stored becomes unreadable:

  ```bash
  sudo cat /opt/dockhand/.encryption_key | base64 -w0
  ```

`.env` is gitignored, so it becomes the only copy on the Pi. Keep one in a
password manager.


## Start

```bash
cp .env.example .env   # fill in DOCKER_GID and ENCRYPTION_KEY
docker compose up -d
docker compose logs -f dockhand
```


## First-run configuration

In the UI:

1. Create an admin account and enable authentication.
2. Add this git repository as a source. Point it at the directory containing the
   compose file for each stack (e.g. `serivces/homepage`).
3. Register Media PI as an environment via Hawser.
4. Create one stack per service, choosing the right host and the right compose
   path in the repo.

Keep secrets in the per-stack `.env` managed inside Dockhand, not in this repo.


## Notes on the proxy setup

- `TRUST_FORWARDED_HEADERS=true` gives correct client IPs in the activity log and
  makes API-token rate limiting work behind Traefik. Trade-off: port 3000 is
  published on all interfaces for the fallback path, so anything on the Infra
  VLAN can spoof its logged IP by hitting that port directly.
- `COOKIE_SECURE` is intentionally left unset. Traefik's `default-headers`
  middleware already injects `X-Forwarded-Proto: https`, so auto-detection works
  on the proxied path — forcing it to `true` would break login over the plain-HTTP
  `10.0.20.53:3000` fallback.
- `DISABLE_LOCAL_LOGIN` should only be set once Authentik/OIDC is live. Setting it
  before then locks you out.

If container memory shows as 0B in the UI, that is the host cgroup setting, not
Dockhand — see [`machines/core-pi/README.md`](../../machines/core-pi/README.md).


## Update

The image tag is pinned, so Renovate opens a PR when a new version ships. Merge
it, then apply it by hand on Core PI — this stack is outside the GitOps loop, and
Dockhand cannot recreate its own container:

```bash
cd /path/to/home-server/serivces/dockhand
git pull
docker compose pull
docker compose up -d
docker compose logs -f dockhand
```

Read the upstream release notes before merging a major bump; Renovate labels
those `major`.

To roll back, set the previous tag in `compose.yml` and re-run the same commands.

## Rollback

```bash
docker compose down
```

`/opt/dockhand` is untouched by `down`, so bringing the stack back up restores
all configured sources, hosts, and stacks.