# Rocky Pi-hole

This stack runs Pi-hole in Docker on Rocky/DietPi.

This stack is **not managed by Dockhand**: Pi-hole is on the same
chicken-and-egg loop as Dockhand itself, since Dockhand can't `git pull` from
GitHub if the local resolver is broken. It is brought up by hand on Rocky and
updated by re-running `docker compose pull && docker compose up -d` there.
Renovate still opens PRs against the image tag.

It is designed to run next to the Rocky Traefik stack:

- Pi-hole DNS binds Rocky's `10.0.20.53:53`.
- Pi-hole web binds only `127.0.0.1:8080`.
- Pi-hole DHCP and NTP are disabled in the container.
- Traefik owns Rocky's public `80` and `443`.
- Traefik proxies `pi-hole.local.jabbas.dev` to `http://127.0.0.1:8080`.

The `address=/local.jabbas.dev/10.0.20.53` wildcard is managed through
`FTLCONF_misc_dnsmasq_lines`, so `*.local.jabbas.dev` resolves to Rocky.

Don't port-forward Rocky's DNS to the internet. This resolver is for LAN/VLAN
clients only; exposing `:53` publicly would make it an open resolver.

## Local DNS Model

Local DNS is intentionally split into two kinds of names:

| Name pattern | Answer | Purpose |
| --- | --- | --- |
| `*.local.jabbas.dev` | `10.0.20.53` | Send service traffic to Rocky Traefik first |
| `*.machine.local.jabbas.dev` | explicit host IPs | Direct machine/backend access |

The machine names are explicit host records in `FTLCONF_dns_hosts`. Those
individual host records should answer before the broader
`address=/local.jabbas.dev/10.0.20.53` wildcard, which is why the validation
commands below check both service names and machine names.

## Files

```text
compose.yml       Docker Compose service
.env.example      Required local environment values
etc-pihole/       Runtime Pi-hole state, ignored by git
```

Pi-hole state lives in `./etc-pihole/` next to `compose.yml`, bind-mounted to
`/etc/pihole` inside the container. The directory is gitignored.

## Configure

From this directory:

```bash
cp .env.example .env
chmod 600 .env
mkdir -p etc-pihole
```

Edit `.env`:

```bash
TIMEZONE=Europe/Stockholm
PIHOLE_WEB_PASSWORD=<admin-password>
```

`compose.yml` pins the important runtime behavior:

- `FTLCONF_webserver_domain=pi-hole.local.jabbas.dev`
- `FTLCONF_webserver_port=127.0.0.1:8080`
- `FTLCONF_dns_interface=eth0`
- `FTLCONF_dns_listeningMode=SINGLE`
- `FTLCONF_dns_upstreams=1.1.1.1, 1.0.0.1`
- `FTLCONF_dns_domainNeeded=true`
- `FTLCONF_dns_expandHosts=true`
- `FTLCONF_dns_rateLimit_count=10000`
- `FTLCONF_dhcp_active=false`
- `FTLCONF_ntp_ipv4_active=false`
- `FTLCONF_ntp_ipv6_active=false`
- `FTLCONF_ntp_sync_active=false`
- `FTLCONF_misc_dnsmasq_lines=address=/local.jabbas.dev/10.0.20.53`

The image tag is pinned to a date-based Pi-hole Docker release instead of
`latest`, so upgrades are explicit. Renovate opens PRs for new tags.

Machine records are managed via `FTLCONF_dns_hosts` in `compose.yml`. The
`*.local.jabbas.dev` wildcard covers service names, so don't add individual
service CNAMEs in the Pi-hole UI.

## Start

```bash
docker compose config
docker compose up -d
docker compose logs -f pihole
```

Open `https://pi-hole.local.jabbas.dev/admin/` through Traefik.

## Subscribed Lists

Subscribed lists are managed in the Pi-hole UI. The current set:

| Address | Status | Comment |
| --- | --- | --- |
| `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` | Enabled | ads |
| `https://v.firebog.net/hosts/Easyprivacy.txt` | Enabled | Privacy |
| `https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt` | Enabled | windows spy |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/alexa` | Enabled | alexa |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/apple` | Enabled | apple |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/huawei` | Enabled | huawei |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/samsung` | Enabled | samsung |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/sonos` | Enabled | sonos |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/windows` | Enabled | windows |
| `https://raw.githubusercontent.com/nextdns/native-tracking-domains/main/domains/xiaomi` | Enabled | xiaomi |
| `https://raw.githubusercontent.com/lassekongo83/Frellwits-filter-lists/master/Frellwits-Swedish-Hosts-File.txt` | Enabled | ads |
| `https://v.firebog.net/hosts/AdguardDNS.txt` | Enabled | ads |
| `https://urlhaus.abuse.ch/downloads/hostfile` | Enabled | malware |
| `https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/gambling-onlydomains.txt` | Enabled | gambling |
| `https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt` | Enabled | |
| `https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts` | Enabled | misc |
| `https://v.firebog.net/hosts/static/w3kbl.txt` | Enabled | misc |
| `https://adaway.org/hosts.txt` | Enabled | ads |
| `https://v.firebog.net/hosts/Admiral.txt` | Enabled | ads |
| `https://v.firebog.net/hosts/Prigent-Ads.txt` | Enabled | tracking |
| `https://blocklistproject.github.io/Lists/ads.txt` | Disabled | ads |
| `https://blocklistproject.github.io/Lists/tracking.txt` | Enabled | tracking |

## Validation

Check listeners:

```bash
sudo ss -ltnup | grep -E ':(53|80|443|8080)\b'
```

Expected shape:

- `pihole-FTL` inside the container listens on `:53`.
- `pihole-FTL` listens on `127.0.0.1:8080` for the web UI.
- Traefik listens on `:80` and `:443`.
- Nothing in this stack should listen on NTP port `:123`.

Check DNS:

```bash
dig @10.0.20.53 pi-hole.local.jabbas.dev +short
dig @10.0.20.53 home-assistant.local.jabbas.dev +short
dig @10.0.20.53 homepage.local.jabbas.dev +short
dig @10.0.20.53 jellyfin.local.jabbas.dev +short
dig @10.0.20.53 rocky.machine.local.jabbas.dev +short
dig @10.0.20.53 apps.machine.local.jabbas.dev +short
dig @10.0.20.53 example.com +short
```

The service names should return Rocky:

```text
10.0.20.53
```

The machine names should return their direct backend IPs:

```text
rocky.machine.local.jabbas.dev -> 10.0.20.53
apps.machine.local.jabbas.dev -> 192.168.20.103
```

Check the local web backend:

```bash
curl -I http://127.0.0.1:8080/admin/
```

Then check the Traefik route:

```bash
curl -I https://pi-hole.local.jabbas.dev/admin/
```

## Rollback

```bash
docker compose down
```
