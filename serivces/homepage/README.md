# Rocky Homepage

Homepage dashboard for the homelab. Runs on Rocky alongside Pi-hole, Traefik,
and Dockhand. Rocky Traefik publishes it at `https://homepage.local.jabbas.dev`
and proxies to `http://127.0.0.1:3001`.

## Security

This route intentionally has no Traefik basic auth. Keep it LAN/VLAN-only and do
not publish it directly to the internet. Homepage can display data from private
services through widgets, and Homepage itself does not provide an authentication
layer.

## Config

```text
config/bookmarks.yaml
config/custom.css
config/custom.js
config/docker.yaml
config/proxmox.yaml
config/services.yaml
config/settings.yaml
config/widgets.yaml
```

## Configure

From this directory:

```bash
cp .env.example .env
chmod 600 .env
```

Edit `.env` and fill in the Homepage widget API values from your password
manager.

`compose.yml` binds Homepage to `127.0.0.1:3001` only. Rocky Traefik is the only
public entry point.

## Start

```bash
docker compose config
docker compose up -d
docker compose logs -f homepage
```

## Validation

Check the local backend:

```bash
curl -I http://127.0.0.1:3001
```

Check the Traefik route:

```bash
curl -I https://homepage.local.jabbas.dev
```

Widgets for services hosted on `apps-vm` will show errors while `apps-vm` is
powered off. The links still work again once `apps-vm` is online.

## Rollback

```bash
docker compose down
```
