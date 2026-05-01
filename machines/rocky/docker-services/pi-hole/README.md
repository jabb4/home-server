# Rocky Pi-hole

This stack runs Pi-hole in Docker on Rocky/DietPi.

It is designed to run next to the Rocky Traefik stack:

- Pi-hole DNS binds Rocky's `10.0.20.53:53`.
- Pi-hole web binds only `127.0.0.1:8080`.
- Pi-hole DHCP and NTP are disabled in the container.
- Traefik owns Rocky's public `80` and `443`.
- Traefik proxies `pi-hole.local.jabbas.dev` to `http://127.0.0.1:8080`.

The `address=/local.jabbas.dev/10.0.20.53` wildcard is managed through
`FTLCONF_misc_dnsmasq_lines`, so `*.local.jabbas.dev` resolves to Rocky.

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

Do not create or restore a local DNS record for `proxy.local.jabbas.dev` that
points directly at `10.0.20.80`. That was the old model. With the Rocky edge
setup, service names should resolve to Rocky, and Rocky Traefik forwards to
Kubernetes Traefik at `10.0.20.80` only for names it does not serve directly.

## Files

```text
compose.yml       Docker Compose service
.env.example      Required local environment values
etc-pihole/       Runtime Pi-hole state, ignored by git
```

## Before Migrating

Export a Pi-hole Teleporter backup from the current standalone install before
stopping it.

Check which service owns DNS and web ports:

```bash
sudo ss -ltnup | grep -E ':(53|80|443|8080)\b'
```

When Traefik is also running on Rocky, only these public ports should be used:

- Pi-hole: `53/tcp` and `53/udp`
- Traefik: `80/tcp` and `443/tcp`
- Pi-hole web: `127.0.0.1:8080/tcp`

Do not port-forward Rocky's DNS service from the internet. This setup is for
LAN/VLAN clients only; exposing `:53` publicly would make it an open resolver.

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
PIHOLE_IMAGE=pihole/pihole:latest
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

Change the upstream DNS servers in `compose.yml` before first start if the
current Pi-hole uses different upstreams.

`PIHOLE_IMAGE` defaults to `pihole/pihole:latest` to follow Pi-hole's current
stable Docker release. Pin it to a date-based tag if you want controlled
upgrade windows.

The current machine records from the standalone `pihole.toml` are managed with
`FTLCONF_dns_hosts`. The old `*.local.jabbas.dev` CNAME records are not carried
over because Rocky now answers those names through the wildcard and forwards to
Kubernetes Traefik only when a route is not served directly on Rocky.

If importing a Teleporter backup, restore adlists/groups/domains, but avoid
restoring old local DNS records that point `proxy.local.jabbas.dev` at
`10.0.20.80`; that would bypass Rocky for the names that should remain
always-on.

## Subscribed Lists

Use Teleporter to migrate subscribed lists from the old Pi-hole:

```text
Settings > System > Teleporter > Backup
Settings > System > Teleporter > Restore
```

When restoring, avoid bringing back old local DNS records that point
`proxy.local.jabbas.dev` at `10.0.20.80`. Rocky should answer
`*.local.jabbas.dev` through the wildcard and then forward to Kubernetes
Traefik only when needed.

If configuring manually, add these subscribed lists in the Pi-hole UI and run
gravity afterwards:

| Address | Status | Comment |
| --- | --- | --- |
| `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts` | Enabled | Migrated from `/etc/` |
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

## Migration

Stop the standalone Pi-hole before starting the container, otherwise port `53`
will conflict:

```bash
sudo systemctl stop pihole-FTL
sudo systemctl disable pihole-FTL
```

If the old install still has a separate web server, stop it too:

```bash
sudo systemctl stop lighttpd 2>/dev/null || true
sudo systemctl disable lighttpd 2>/dev/null || true
```

Start the container:

```bash
docker compose config
docker compose up -d
docker compose logs -f pihole
```

Open `https://pi-hole.local.jabbas.dev/admin/` through Traefik and import the
Teleporter backup if needed.

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
dig @10.0.20.53 argocd.local.jabbas.dev +short
dig @10.0.20.53 rocky.machine.local.jabbas.dev +short
dig @10.0.20.53 stratton-traefik.machine.local.jabbas.dev +short
dig @10.0.20.53 example.com +short
```

The service names should return Rocky:

```text
10.0.20.53
```

The machine names should return their direct backend IPs:

```text
rocky.machine.local.jabbas.dev -> 10.0.20.53
stratton-traefik.machine.local.jabbas.dev -> 10.0.20.80
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

Stop the container:

```bash
docker compose down
```

Re-enable the standalone Pi-hole:

```bash
sudo systemctl enable pihole-FTL
sudo systemctl start pihole-FTL
```

If the old install used `lighttpd`, re-enable it:

```bash
sudo systemctl enable lighttpd
sudo systemctl start lighttpd
```

Confirm DNS is back:

```bash
dig @10.0.20.53 example.com +short
```
