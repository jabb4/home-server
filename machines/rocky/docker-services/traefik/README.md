# Rocky Traefik

Single edge proxy for the homelab. Runs on Rocky/DietPi and fronts every
`*.local.jabbas.dev` route, regardless of which host the backend lives on.

This stack is **not managed by Dockhand**: a bad reconcile here would knock out
`dockhand.local.jabbas.dev` itself, making the GitOps controller unreachable
until somebody SSHes to Rocky. It's brought up by hand and updated by
re-running `docker compose pull && docker compose up -d` on Rocky. Renovate
still opens PRs against the image tag.

Rocky keeps Pi-hole DNS on `10.0.20.53:53`. Pi-hole's web UI moves to
`127.0.0.1:8080`, and Traefik binds Rocky's `80` and `443`.

## Routes

| Host | Backend | Auth |
| --- | --- | --- |
| `homepage.local.jabbas.dev` | `http://127.0.0.1:3001` | No extra auth |
| `pi-hole.local.jabbas.dev` | `http://127.0.0.1:8080` | Pi-hole auth only |
| `dockhand.local.jabbas.dev` | `http://127.0.0.1:3000` | Dockhand auth only |
| `traefik-rocky.local.jabbas.dev` | `api@internal` | Traefik basic auth |
| `home-assistant.local.jabbas.dev` | `http://10.0.20.60:8123` | Home Assistant auth only |
| `unifi.local.jabbas.dev` | `https://192.168.10.1` | UniFi auth only |
| `pikvm.local.jabbas.dev` | `https://192.168.20.62` | PiKVM auth only |
| `pve.local.jabbas.dev` | `https://10.0.10.10:8006` | Proxmox auth only |
| `truenas.local.jabbas.dev` | `https://192.168.20.101` | TrueNAS auth only |
| `jellyfin.local.jabbas.dev` | `http://192.168.20.103:8096` | Jellyfin auth only |
| `seerr.local.jabbas.dev` | `http://192.168.20.103:5055` | Seerr auth only |
| `sabnzbd.local.jabbas.dev` | `http://192.168.20.103:8080` | SABnzbd auth only |
| `sonarr.local.jabbas.dev` | `http://192.168.20.103:8989` | Sonarr auth only |
| `radarr.local.jabbas.dev` | `http://192.168.20.103:7878` | Radarr auth only |
| `prowlarr.local.jabbas.dev` | `http://192.168.20.103:9696` | Prowlarr auth only |
| `bazarr.local.jabbas.dev` | `http://192.168.20.103:6767` | Bazarr auth only |

There is no longer a wildcard fallback. Every routed name has an explicit entry
in `config/dynamic.yml`.

## Prerequisites

- Rocky is reachable at `10.0.20.53`.
- Pi-hole v6 is installed on Rocky (Compose stack at `../pi-hole/`).
- Docker and Docker Compose are installed on Rocky.
- The Cloudflare token is scoped to `jabbas.dev` with `Zone / Zone / Read` and
  `Zone / DNS / Edit`.
- Rocky can reach every backend IP listed in the routes table.

Install helper tools if needed:

```bash
sudo apt update
sudo apt install -y apache2-utils dnsutils
```

## Local DNS

The wildcard `address=/local.jabbas.dev/10.0.20.53` is set by the Pi-hole
Compose stack at [`../pi-hole`](../pi-hole). Every `*.local.jabbas.dev` name
resolves to Rocky's IP and lands on this Traefik.

If Pi-hole is still running directly on DietPi instead of in Compose, mirror the
override through Pi-hole v6's FTL config:

```bash
sudo pihole-FTL --config misc.dnsmasq_lines '["address=/local.jabbas.dev/10.0.20.53"]'
sudo pihole restartdns
```

Remove any conflicting Pi-hole local DNS records or CNAMEs for hostnames in the
routes table.

## Home Assistant Proxy Trust

Home Assistant must trust Rocky as a reverse proxy, otherwise proxied requests
and websocket connections can fail:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.0.20.53/32
```

## Prepare Traefik State

From this directory:

```bash
cp .env.example .env
chmod 600 .env
mkdir -p acme
touch acme/acme.json
chmod 600 acme/acme.json
```

Edit `.env`:

```bash
TIMEZONE=Europe/Stockholm
ACME_EMAIL=<your-email>
CF_DNS_API_TOKEN=<cloudflare-dns-token>
TRAEFIK_BASIC_AUTH_USERS='<user>:<bcrypt-hash>'
```

Generate the basic-auth value:

```bash
htpasswd -nbB <user> <password>
```

Copy the full output into `.env` as `TRAEFIK_BASIC_AUTH_USERS`. Keep the single
quotes around the value because the bcrypt hash contains `$`.
This basic auth is only used for `traefik-rocky.local.jabbas.dev`.

To generate it without putting the password in shell history:

```bash
read -rs TRAEFIK_BASIC_AUTH_PASSWORD
htpasswd -nbB <user> "$TRAEFIK_BASIC_AUTH_PASSWORD"
unset TRAEFIK_BASIC_AUTH_PASSWORD
```

## Start

Validate and start the stack:

```bash
docker compose config
docker compose up -d
docker compose logs -f traefik
```

Traefik uses Cloudflare DNS-01 to request a wildcard certificate for
`local.jabbas.dev` and `*.local.jabbas.dev`. The ACME account and certificates
are stored in `acme/acme.json`, which must not be committed.

## Validation

Check DNS:

```bash
dig @10.0.20.53 jellyfin.local.jabbas.dev +short
```

Should return:

```text
10.0.20.53
```

Check listeners on Rocky:

```bash
sudo ss -ltnup | grep -E ':(53|80|443|3000|3001|8080)\b'
```

Expected shape:

- Pi-hole DNS listens on `:53`.
- Traefik listens on `:80` and `:443`.
- Pi-hole web listens on `127.0.0.1:8080`.
- Dockhand listens on `127.0.0.1:3000`.
- Homepage listens on `127.0.0.1:3001`.

Check routes:

```bash
curl -I https://homepage.local.jabbas.dev
curl -I https://pi-hole.local.jabbas.dev/admin/
curl -I https://dockhand.local.jabbas.dev
curl -I https://home-assistant.local.jabbas.dev
curl -I https://jellyfin.local.jabbas.dev
curl -I https://traefik-rocky.local.jabbas.dev/dashboard/
```

`traefik-rocky.local.jabbas.dev` should return `401` until credentials are
provided. The other routes should use their own application auth, not Traefik
basic auth.

## Rollback

Stop Rocky Traefik:

```bash
docker compose down
```

Restore Pi-hole's default web ports if Pi-hole is running directly on DietPi
rather than in the `../pi-hole` Compose stack:

```bash
sudo pihole-FTL --config webserver.port "80o,443os,[::]:80o,[::]:443os"
sudo systemctl restart pihole-FTL
```
