# Authentik

This workload deploys authentik into the `infra` namespace through the local
`resources` chart, which depends on the upstream Helm chart and wires it to the
shared `postgres` CloudNativePG cluster.

The workload is intentionally committed in a migration-safe state:

- `server.enabled` and `worker.enabled` are both `false`
- the old Docker deployment remains the live service until you restore data
- the ingress for `auth.local.jabbas.dev` stays disabled here until cutover

That keeps Argo CD from starting a fresh empty authentik instance against the
new database before you have restored the existing data and set the current
`AUTHENTIK_SECRET_KEY`.

Secret flow:

- non-sensitive chart settings stay in `resources/values.yaml`
- the wrapper chart reads `resources/secrets.sops.yaml` through `helm-secrets`
- authentik renders its own Kubernetes Secret so secret changes update the pod
  template and roll the deployment

Files:

- `application.yaml`: Argo CD application for the local wrapper chart
- `resources/`: wrapper Helm chart with the upstream authentik dependency and repo-owned PVCs
- `resources/values.yaml`: non-sensitive authentik chart values, including the shared PostgreSQL connection wiring
- `resources/secrets.sops.yaml`: encrypted `AUTHENTIK_SECRET_KEY` values for the upstream chart

## Forward Auth

This repo currently uses authentik forward auth in single-application mode with
Traefik.

To protect an app host such as `homepage.local.jabbas.dev`, you need both:

- the shared Traefik middleware `infra-forward-auth-authentik@kubernetescrd`
- a public route on the same host for `/outpost.goauthentik.io/` that forwards
  to the authentik server service in `infra`

The outpost path must stay publicly reachable. Without that extra route,
requests such as
`https://homepage.local.jabbas.dev/outpost.goauthentik.io/ping` return `404`
and forward auth does not work.

Homepage shows the current pattern:

- add `infra-forward-auth-authentik@kubernetescrd` to the app ingress
  middlewares
- add a Traefik `IngressRoute` for
  `Host(app-host) && PathPrefix(/outpost.goauthentik.io/)`
- point that route to `authentik-upstream-server` in namespace `infra` on port
  `9000`

Quick check:

- `curl -vk https://app-host/outpost.goauthentik.io/ping`
- expected result: `204 No Content`

Migration steps after this workload syncs:

1. Replace the placeholder secret key in `resources/secrets.sops.yaml` with the current Docker `AUTHENTIK_SECRET_KEY`.
2. Restore the old PostgreSQL data into the new `postgres` cluster.
3. Copy the old `/data`, `/templates`, and `/certs` content into the new PVCs.
4. Set `upstream.server.enabled: true` and `upstream.worker.enabled: true` in `resources/values.yaml`.
5. Remove the old external Traefik route for `auth.local.jabbas.dev` and enable the new ingress.
