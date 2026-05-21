# Rocky

Rocky is the Raspberry Pi 5 that runs the always-on control plane for the
homelab.

Services:

- Pi-hole DNS on `10.0.20.53`
- Traefik edge proxy (the single ingress for every `*.local.jabbas.dev` route)
- Dockhand GitOps controller for every Docker host
- Homepage dashboard on `homepage.local.jabbas.dev`

Service docs:

- [`docker-services/dockhand/README.md`](docker-services/dockhand/README.md)
- [`docker-services/pi-hole/README.md`](docker-services/pi-hole/README.md)
- [`docker-services/traefik/README.md`](docker-services/traefik/README.md)
- [`docker-services/managed/homepage/README.md`](docker-services/managed/homepage/README.md)

`dockhand`, `pi-hole`, and `traefik` live outside `managed/` and are brought up
by hand on Rocky — not reconciled by Dockhand, since a bad reconcile to any of
them would break the GitOps control plane itself. Everything else under
`managed/` is Dockhand-reconciled.
