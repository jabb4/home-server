# Postgres

This chart creates the shared PostgreSQL cluster in the `infra` namespace using
CloudNativePG.

Current behavior:

- deploys a single-instance PostgreSQL 16 cluster named `postgres`
- stores cluster state on the `longhorn` storage class
- keeps a registry of app databases in `values.yaml`
- creates one database credential Secret per app
- bootstraps the first app from that registry
- manages app roles declaratively in the `Cluster` spec
- manages app databases declaratively with `Database` resources
- keeps PostgreSQL superuser access disabled for normal app onboarding

This is a shared infra database service. New workloads should add themselves to
the app registry here rather than creating a second PostgreSQL operator stack.

App registry:

- each entry in `apps:` declares one service that uses this shared cluster
- each app gets its own database, role, and Kubernetes Secret
- app secrets are created in `infra` for CloudNativePG role reconciliation and copied to the app
  namespace when the workload lives elsewhere
- `cluster.bootstrapApp` selects which app seeds the very first database during
  cluster init
- database names and usernames should use lowercase letters, digits, and
  underscores so the role and database mapping stays predictable
- app roles and databases are then reconciled by CloudNativePG itself, not by
  custom SQL jobs

Adding a new service:

1. Add a new entry under `apps:` in `values.yaml`.
2. Add that app password under `appSecrets:` in `secrets.sops.yaml`.
3. Point the service at `postgres-rw.infra.svc.cluster.local`.
4. Read the password from the Secret name declared for that app.

Example:

```yaml
apps:
  - name: paperless
    namespace: apps
    database: paperless
    username: paperless
    secretName: postgres-paperless-app
```

```yaml
appSecrets:
  paperless:
    password: change-me
```

The chart will then:

- create the app Secret in the target namespace
- reconcile the PostgreSQL role through `spec.managed.roles`
- reconcile the database through a `Database` custom resource

Files:

- `application.yaml`: Argo CD application for the local chart
- `values.yaml`: cluster defaults plus the app database registry
- `secrets.example.yaml`: plaintext schema for encrypted app passwords
- `secrets.sops.yaml`: encrypted app passwords consumed by Argo CD

Editing secrets:

1. `just edit-sops workloads/infra/postgres/secrets.sops.yaml`
2. Keep `appSecrets.<app>.password` aligned with the service that uses it.

If you need to create a fresh encrypted file:

1. `cp workloads/infra/postgres/secrets.example.yaml workloads/infra/postgres/secrets.sops.yaml`
2. `just encrypt-sops workloads/infra/postgres/secrets.sops.yaml`
