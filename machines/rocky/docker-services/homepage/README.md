# Rocky Homepage

This stack runs Homepage in Docker on Rocky/DietPi so the dashboard remains
available while Stratton is powered off.

Rocky Traefik publishes it at `https://homepage.local.jabbas.dev` and proxies to
`http://127.0.0.1:3001`.

## Security

This route intentionally has no Traefik basic auth. Keep it LAN/VLAN-only and do
not publish it directly to the internet. Homepage can display data from private
services through widgets, and Homepage itself does not provide an authentication
layer.

## Config

The `config/` directory is copied from the Kubernetes Homepage config:

```text
config/bookmarks.yaml
config/custom.css
config/custom.js
config/docker.yaml
config/kubernetes.yaml
config/proxmox.yaml
config/services.yaml
config/settings.yaml
config/widgets.yaml
```

The Rocky copy is intentionally separate from the Kubernetes chart so Rocky can
be deployed from its own Docker services directory.

## Configure

From this directory:

```bash
cp .env.example .env
chmod 600 .env
```

Edit `.env` and copy the Homepage API values from the current Kubernetes
`homepage-secrets` values or from your password manager.

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

With Stratton offline, Homepage should still load. Services that live on
Stratton or in Kubernetes may show as down until Stratton is powered on.

Widgets for services hosted on Stratton may show errors while Stratton is
powered off. The links still work again once Stratton is online.

## Rollback

```bash
docker compose down
```
