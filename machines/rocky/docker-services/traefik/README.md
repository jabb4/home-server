# Rocky Traefik

This stack runs a standalone Traefik edge proxy on Rocky/DietPi. It is the
always-on front door for `*.local.jabbas.dev` while Stratton can be powered off.

Rocky keeps Pi-hole DNS on `10.0.20.53:53`. Pi-hole's web UI moves to
`127.0.0.1:8080`, and Traefik binds Rocky's `80` and `443`.

## Routes

| Host | Backend | Auth |
| --- | --- | --- |
| `home-assistant.local.jabbas.dev` | `http://10.0.20.60:8123` | Home Assistant auth only |
| `unifi.local.jabbas.dev` | `https://192.168.10.1` | UniFi auth only |
| `pi-hole.local.jabbas.dev` | `http://127.0.0.1:8080` | Pi-hole auth only |
| `homepage.local.jabbas.dev` | `http://127.0.0.1:3001` | No extra auth |
| `pikvm.local.jabbas.dev` | `https://192.168.20.62` | PiKVM auth only |
| `traefik-rocky.local.jabbas.dev` | `api@internal` | Traefik basic auth |
| `*.local.jabbas.dev` fallback | `https://10.0.20.80` | Kubernetes Traefik handles the route |

The fallback route lets Kubernetes-hosted names keep working through Rocky when
Stratton is online. When Stratton is offline, only the always-on routes above
remain available.

## Prerequisites

- Rocky is reachable at `10.0.20.53`.
- Pi-hole v6 is installed on Rocky.
- Docker and Docker Compose are installed on Rocky.
- The Cloudflare token is scoped to `jabbas.dev` with `Zone / Zone / Read` and
  `Zone / DNS / Edit`.
- Rocky can reach `10.0.20.60`, `192.168.10.1`, `192.168.20.62`, and
  `10.0.20.80`.

Install helper tools if needed:

```bash
sudo apt update
sudo apt install -y apache2-utils dnsutils
```

## Pi-hole Web UI

If Pi-hole is running from [`../pi-hole`](../pi-hole), this is already handled
by that Compose stack.

If Pi-hole is still installed directly on DietPi, move Pi-hole's web UI away
from `80` and `443` so Traefik can bind them:

```bash
sudo pihole-FTL --config webserver.domain "pi-hole.local.jabbas.dev"
sudo pihole-FTL --config webserver.port "127.0.0.1:8080"
sudo systemctl restart pihole-FTL
```

Confirm Pi-hole still listens for DNS on `53` and only exposes the web UI on
localhost:

```bash
sudo ss -ltnup | grep -E ':(53|80|443|8080)\b'
curl -I http://127.0.0.1:8080/admin/
```

## Configure Local DNS

If Pi-hole is running from [`../pi-hole`](../pi-hole), this is already handled
by that Compose stack with:

```yaml
FTLCONF_misc_dnsmasq_lines: |-
  address=/local.jabbas.dev/10.0.20.53
```

If Pi-hole is still installed directly on DietPi, configure the same wildcard
through Pi-hole v6's FTL config:

```bash
sudo pihole-FTL --config misc.dnsmasq_lines '["address=/local.jabbas.dev/10.0.20.53"]'
sudo pihole restartdns
```

Do not rely on `/etc/dnsmasq.d/` unless `misc.etc_dnsmasq_d` is enabled.

Remove conflicting Pi-hole local DNS records or CNAMEs for service names if
they point directly at `10.0.20.80` or at an old `proxy.local.jabbas.dev`
record. That includes the always-on names:

```text
home-assistant.local.jabbas.dev
unifi.local.jabbas.dev
pi-hole.local.jabbas.dev
homepage.local.jabbas.dev
pikvm.local.jabbas.dev
traefik-rocky.local.jabbas.dev
```

Kubernetes-only names can also resolve through the wildcard because Rocky
Traefik forwards unknown `*.local.jabbas.dev` hosts to `10.0.20.80`.

## Home Assistant Proxy Trust

Home Assistant must trust Rocky as a reverse proxy, otherwise proxied requests
and websocket connections can fail. The current Home Assistant docs use the
whole services VLAN, which covers both Kubernetes Traefik and Rocky:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 10.0.20.0/24
```

If that is narrowed later, keep `10.0.20.53` in the trusted proxy list.

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

Example:

```bash
TRAEFIK_BASIC_AUTH_USERS='admin:$2y$05$replace-with-the-generated-hash'
```

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

Container logs are written to Docker's `json-file` logger with size limits in
`compose.yml`.

## Validation

Check DNS:

```bash
dig @10.0.20.53 home-assistant.local.jabbas.dev +short
dig @10.0.20.53 argocd.local.jabbas.dev +short
```

Both should return:

```text
10.0.20.53
```

Check listeners on Rocky:

```bash
sudo ss -ltnup | grep -E ':(53|80|443|8080)\b'
```

Expected shape:

- Pi-hole DNS listens on `:53`.
- Traefik listens on `:80` and `:443`.
- Pi-hole web listens on `127.0.0.1:8080`.

Check routes:

```bash
curl -I https://home-assistant.local.jabbas.dev
curl -I https://pi-hole.local.jabbas.dev/admin/
curl -I https://homepage.local.jabbas.dev
curl -I https://unifi.local.jabbas.dev
curl -I https://pikvm.local.jabbas.dev
curl -I https://traefik-rocky.local.jabbas.dev/dashboard/
```

`traefik-rocky.local.jabbas.dev` should return `401` until credentials are
provided. The other always-on routes should use their own application auth, not
Traefik basic auth.

With Stratton online, also test a Kubernetes-only hostname:

```bash
curl -I https://argocd.local.jabbas.dev
```

With Stratton offline, the always-on routes should still answer. Kubernetes-only
routes should return a Traefik upstream error until Stratton is powered on.

## Rollback

Stop Rocky Traefik:

```bash
docker compose down
```

Restore Pi-hole's default web ports:

```bash
sudo pihole-FTL --config webserver.port "80o,443os,[::]:80o,[::]:443os"
sudo systemctl restart pihole-FTL
```

Remove or disable the wildcard DNS override if needed:

```bash
sudo pihole-FTL --config misc.dnsmasq_lines '[]'
sudo pihole restartdns
```

Only reset `misc.dnsmasq_lines` to `[]` if this wildcard was the only custom
dnsmasq line.
