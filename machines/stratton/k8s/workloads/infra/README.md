# Infra workloads

This directory contains shared infrastructure services for the Stratton cluster.

Infra means services that other workloads depend on or operators use to run the
cluster, for example:

- ingress controllers
- identity and auth
- certificate management
- monitoring and uptime
- shared databases and backing services

Cluster-core components such as `foundations`, `Cilium`, and `Argo CD` live in
`../cluster/`, not here.

Current workloads here:

- `authentik/`
- `cert-manager/`
- `cloudnative-pg/`
- `crowdsec/`
- `grafana/`
- `postgres/`
- `prometheus/`
- `traefik/`
- `uptime-kuma/`

`crowdsec/` is still grouped under `infra/` in Git, but it deploys into its
own runtime namespace so the agent can evolve independently from the general
`infra` namespace policy.

Future services such as `Authentik` and shared databases should also live here.

Persistent app state in `infra/` should default to the Longhorn-backed
`longhorn` storage class unless the workload specifically needs a static
TrueNAS NFS share for large shared files.
