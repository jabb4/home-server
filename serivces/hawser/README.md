# Hawser

Hawser is the Dockhand agent. It exposes a remote host's Docker daemon to the
GitOps controller on Core PI so Dockhand can reconcile that host's stacks the
same way it does its own.

Runs in **edge mode**: the agent dials Dockhand outbound over WebSocket, so the
host needs no inbound firewall rule. It also means the agent can only connect
while Traefik is up on Core PI.

This stack is host-agnostic — everything host-specific lives in `.env`.

## Prerequisites

- Dockhand reachable at `https://dockhand.local.jabbas.dev` from this host
- `sudo mkdir -p /opt/hawser/stacks`

## Start

1. In the Dockhand UI: Settings -> Environments -> Add -> Hawser Edge. Name it
   after the host (e.g. `media-pi`). Copy the token — shown once.
2. On the host:

   ```bash
   cp .env.example .env   # fill in AGENT_NAME and HAWSER_TOKEN
   docker compose config
   docker compose up -d
   docker compose logs -f hawser
   ```

3. The environment should flip to connected in Dockhand. Use the Test button to
   confirm.

## Update

The image tag is pinned, so Renovate opens a PR when a new version ships. Merge
it, then apply it by hand on each agent host — Dockhand reconciles through the
agent, so it cannot recreate the agent's own container:

```bash
cd /path/to/home-server/serivces/hawser
git pull
docker compose pull
docker compose up -d
docker compose logs -f hawser
```

To roll back, set the previous tag in `compose.yml` and re-run the same commands.

## Rollback

```bash
docker compose down
```

`/opt/hawser/stacks` is untouched by `down`. Stacks Dockhand deployed keep
running — only the agent goes away, so they stop being reconciled until it is
back.
