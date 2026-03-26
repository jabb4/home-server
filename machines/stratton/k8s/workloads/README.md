# Workloads

This directory contains the deployable Kubernetes workloads managed by Argo CD.

The bootstrap flow works like this:

1. Argo CD is installed from the files in `../bootstrap/`.
2. `root-application.yaml` points Argo CD at this `workloads/` directory.
3. Argo CD loads the `application.yaml` file owned by each workload directory.
4. Those child applications point at the local chart or upstream Helm source for that workload.

That means everything in `workloads/` is part of the GitOps-managed desired state for the cluster.

## Layout

- `cluster/`: cluster bootstrap-managed workloads and shared cluster scaffolding
- `infra/`: shared infrastructure services used to operate or support workloads
- `apps/`: general user-facing services

Each deployable service should live in its own workload directory.

## Current Structure

- `cluster/foundations/`
  - creates shared namespaces such as `infra` and `apps`
  - owns baseline `AppProject` resources and namespace/policy scaffolding
  - owns its own `application.yaml`
- `cluster/cilium/`
  - stores Git-managed values for the upstream `cilium/cilium` chart
  - includes the cluster-specific LB IPAM and L2 announcement resources used
    for bare-metal `LoadBalancer` services
  - owns its own `application.yaml`
- `cluster/argocd/`
  - stores Git-managed values for the upstream `argo/argo-cd` chart
  - owns its own `application.yaml`
- `cluster/longhorn/`
  - deploys Longhorn from the upstream chart into `longhorn-system`
  - uses the built-in `longhorn` StorageClass for durable in-cluster app state
  - keeps optional backup-related resources next to the workload
- `infra/`
  - contains shared services such as ingress, identity, monitoring, uptime, and shared databases
- `infra/cloudnative-pg/`
  - deploys the CloudNativePG operator into `cnpg-system`
  - provides the PostgreSQL control plane used by shared infra databases
- `infra/postgres/`
  - deploys the first shared PostgreSQL cluster into `infra`
  - boots an `authentik` application database on PostgreSQL 16
- `infra/authentik/`
  - deploys authentik from the upstream chart into `infra`
  - keeps the migration state PVCs and secret-key Secret next to the workload
- `infra/traefik/`
  - deploys the Traefik ingress controller from the upstream chart
  - exposes it through a Cilium-managed `LoadBalancer` IP
  - keeps dashboard auth and external route resources next to the workload
- `infra/cert-manager/`
  - deploys cert-manager from the upstream chart into `cert-manager`
  - owns the Cloudflare-backed `ClusterIssuer` and shared wildcard certificates
- `infra/crowdsec/`
  - deploys CrowdSec from the upstream chart into `crowdsec`
  - tails Traefik logs and provides LAPI decisions for the Traefik bouncer plugin
  - keeps the shared Traefik bouncer key next to the workload
- `infra/prometheus/`
  - deploys Prometheus from the upstream chart into `infra`
  - stores metrics on Longhorn
  - keeps a static scrape for the existing Proxmox node exporter during migration
- `infra/grafana/`
  - deploys Grafana from the upstream chart into `infra`
  - provisions Prometheus as the default datasource
  - keeps the admin password in an encrypted workload-local values file
- `apps/homepage/`
  - deploys the Homepage dashboard
  - mounts committed config files through a ConfigMap
  - consumes API keys and credentials from an encrypted `secrets.sops.yaml` Helm values file
  - owns its own `application.yaml`
- `infra/uptime-kuma/`
  - deploys Uptime Kuma
  - currently uses a PVC for `/app/data`
  - owns its own `application.yaml`

## Adding A New Service

For a new service:

1. Create a new workload directory under the correct domain, for example:
   - `cluster/<service-name>/`
   - `infra/<service-name>/`
   - `apps/<service-name>/`
2. Add at least:
   - `application.yaml`
3. For local charts, also add:
   - `Chart.yaml`
   - `values.yaml`
   - `templates/`
4. Choose the correct destination namespace and source in that workload's `application.yaml`.
5. If the service needs shared namespace or policy changes, add those to `cluster/foundations/`, not to the app chart itself.
6. If the service needs sensitive values, keep them in a chart-local `secrets.sops.yaml` and reference that file from the same workload's `application.yaml`.

When the workload is managed from an upstream Helm repository rather than a
local chart, keep the pinned values and service documentation under
`workloads/<domain>/<service>/` and describe the upstream chart in that
workload's `application.yaml`.

## Storage Conventions

- Use `Longhorn` for durable in-cluster state such as config directories,
  SQLite databases, and shared databases.
- Use static `PersistentVolume` and `PersistentVolumeClaim` manifests for
  `TrueNAS NFS` shares that hold large shared files.
- Keep NFS PV/PVC manifests with the consuming workload instead of creating a
  central storage registry.
- Use Longhorn-backed `StorageClass` names explicitly in workload values instead
  of relying on a default storage class.
- Use the built-in non-default `longhorn` storage class for durable app state.
- Keep app-owned data on Longhorn and file-library data on TrueNAS NFS.

## Design Rules

- Keep one Helm chart per deployable service when that service is rendered from a local chart in this repo.
- For upstream Helm charts managed directly by Argo CD, keep the chart values in `workloads/` even if the rendered manifests come from the upstream repo instead of a local chart directory.
- Keep each workload self-contained by storing its Argo CD `application.yaml` next to its chart or values.
- Keep cluster scaffolding and cluster-core controllers in `cluster/`.
- Keep shared runtime services like ingress, identity, monitoring, and shared databases in `infra/`.
- Keep namespaces and shared policy in `cluster/foundations/`.
- Keep Argo `AppProject` definitions in `cluster/foundations/` so workload charts stay scoped to their own namespace.
- Keep Argo CD bootstrap logic in `../bootstrap/`, but do not use bootstrap as a registry of workloads.
- Put services in a domain directory based on responsibility, not on implementation details.
- Keep sensitive values in SOPS-encrypted Helm values files, not in plain `values.yaml`.
