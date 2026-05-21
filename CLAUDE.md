# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

GitOps source of truth for the Stratton homelab. The repo holds Docker Compose
stacks, host-level configs, and operator runbooks — almost no application code.
**Dockhand on Rocky** is the GitOps controller: it watches `main` and reconciles
each registered stack onto the Docker host that owns it.

The full architectural overview (network layout, machines, who runs what) lives
in `README.md`. Read it first when context is needed.

## How edits land on the running cluster

1. Edit the relevant compose file or config under
   `machines/<host>/docker-services/managed/<service>/`.
2. Commit and push to `main`.
3. Dockhand pulls the change on its next sync and reconciles the stack on the
   target host.

Local-only changes do not affect any host. Always commit + push when you want
state to converge.

Dockhand itself lives at `machines/rocky/docker-services/dockhand/`, **not**
under `managed/`. It bootstraps the GitOps loop, so it has to be brought up by
hand on Rocky once before anything else can be managed. Edits to that stack are
applied by re-running `docker compose up -d` on Rocky, not via Dockhand.

## Hosts and what runs where

- **Rocky** (`10.0.20.53`, RPi 5) — always-on control plane: Pi-hole, Traefik,
  Dockhand, Homepage.
- **`apps-vm`** (`192.168.20.103`, on Stratton) — Jellyfin + media-downloader
  stack (gluetun, SABnzbd, Prowlarr, Sonarr, Radarr, Bazarr, Seerr) + Recyclarr.
  Mounts large libraries from TrueNAS NFS.
- **TrueNAS** (`192.168.20.101`, on Stratton) — file storage; NFS shares for
  media data.
- **Home Assistant Pi**, **NUT Pi**, **PiKVM**, **SLZB-MR4U** — dedicated
  hardware; not Docker hosts managed by Dockhand.

## Ingress

Rocky Traefik is the **only** edge proxy. Every `*.local.jabbas.dev` name
resolves to Rocky via the Pi-hole wildcard
`address=/local.jabbas.dev/10.0.20.53` and is routed to the right backend by
explicit entries in
`machines/rocky/docker-services/managed/traefik/config/dynamic.yml`.
There is no wildcard fallback — adding a new public name means adding a router
and a service to that file.

When adding a new routed service:

1. Add it to `dynamic.yml` (router + service + appropriate middleware chain).
2. Add it to the routes table in
   `machines/rocky/docker-services/managed/traefik/README.md`.
3. Add it to
   `machines/rocky/docker-services/managed/homepage/config/services.yaml` if it
   should appear on the dashboard.

## Per-stack conventions

Each Compose stack lives in its own directory with this shape:

```
compose.yml         # the stack
.env.example        # required env vars, no secrets
README.md           # what it does, prerequisites, start/validate/rollback
```

- The real `.env` is gitignored and lives on the host. Dockhand stores secrets
  per-stack in its own `.env` mechanism; the repo's `.env.example` only
  documents what keys are needed.
- Pin images by version tag only (e.g. `traefik:v3.6`), no `@sha256:` digests.
  Renovate (`.github/renovate.json`) opens PRs for new tag versions and ignores
  digest changes. Don't reintroduce digest pins — Renovate is configured to
  skip `digest` and `pinDigest` updates entirely.
- Compose stacks that bind privileged ports or expose the Docker socket should
  set `security_opt: [no-new-privileges:true]` and, where it makes sense, bind
  to `127.0.0.1:` so Traefik is the only public path in.

## Validation / CI

- **`./scripts/scan-secrets.sh`** — local gitleaks scan. Same scan runs in CI on
  every push/PR via `.github/workflows/secret-scan.yml`. Allowlist:
  `.gitleaks.toml`. Historical findings: `.gitleaksignore`.

There is no longer a GitOps-validate workflow; the previous one targeted the
deleted k8s tree.

## Out-of-cluster pieces

- `nixos/` — flake-based NixOS config for `apps-vm`. Rebuild from the host with
  `sudo nixos-rebuild switch --flake .#apps-vm`.
- `machines/stratton/` — Proxmox host notes (BIOS, install, NUT setup).
- `machines/<name>/` — docs and host-specific notes for non-Stratton hardware.
