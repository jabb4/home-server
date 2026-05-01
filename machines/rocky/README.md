# Rocky

Rocky is the Raspberry Pi 5 that runs DNS and always-on edge routing.

Services:

- Pi-hole DNS on `10.0.20.53`
- Standalone Traefik edge proxy for always-on `*.local.jabbas.dev` routes
- Homepage dashboard on `homepage.local.jabbas.dev`

Service docs:

- [`docker-services/pi-hole/README.md`](docker-services/pi-hole/README.md)
- [`docker-services/homepage/README.md`](docker-services/homepage/README.md)
- [`docker-services/traefik/README.md`](docker-services/traefik/README.md)
