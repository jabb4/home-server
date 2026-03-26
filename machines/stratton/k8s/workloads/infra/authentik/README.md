# Authentik

This workload deploys authentik from the upstream Helm chart into the `infra`
namespace and wires it to the shared `postgres` CloudNativePG cluster.

The workload is intentionally committed in a migration-safe state:

- `server.enabled` and `worker.enabled` are both `false`
- the old Docker deployment remains the live service until you restore data
- the ingress for `auth.local.jabbas.dev` stays disabled here until cutover

That keeps Argo CD from starting a fresh empty authentik instance against the
new database before you have restored the existing data and set the current
`AUTHENTIK_SECRET_KEY`.

Secret flow:

- non-sensitive chart settings stay in `values.yaml`
- the upstream chart reads `secrets.sops.yaml` through `helm-secrets`
- authentik renders its own Kubernetes Secret so secret changes update the pod
  template and roll the deployment

Files:

- `application.yaml`: Argo CD application for the upstream chart plus local resources
- `values.yaml`: non-sensitive authentik chart values, including the shared PostgreSQL connection wiring
- `secrets.sops.yaml`: encrypted `AUTHENTIK_SECRET_KEY` values for the upstream chart
- `resources/`: PVCs and other repo-owned support resources

Migration steps after this workload syncs:

1. Replace the placeholder secret key in `secrets.sops.yaml` with the current Docker `AUTHENTIK_SECRET_KEY`.
2. Restore the old PostgreSQL data into the new `postgres` cluster.
3. Copy the old `/data`, `/templates`, and `/certs` content into the new PVCs.
4. Set `server.enabled: true` and `worker.enabled: true` in `values.yaml`.
5. Remove the old external Traefik route for `auth.local.jabbas.dev` and enable the new ingress.
