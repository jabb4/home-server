# Longhorn

This workload installs Longhorn as the cluster storage subsystem.

Current design:

- all nodes use a `100GiB` Talos system disk
- every worker gets a dedicated `200GiB` Longhorn disk
- worker disk serials should follow `<worker-name>-longhorn`
- the Longhorn UI stays behind a `ClusterIP` service and is published
  internally through Traefik at `longhorn.local.jabbas.dev`

Longhorn is used for durable in-cluster app state such as config directories,
SQLite databases, and shared databases.

TrueNAS NFS is not provisioned by Longhorn. Large shared file data should stay
on static app-owned NFS shares managed by the consuming workload.

Longhorn only creates storage disks on nodes labeled with
`node.longhorn.io/create-default-disk=true`. In this repo, workers are storage
nodes by default: `just cluster-init` labels the initial workers automatically,
and `just add-worker <node>` labels new workers automatically after they join.
That lets you add new storage workers without editing this workload as long as
the node has a dedicated Talos-mounted disk at `/var/mnt/longhorn`.

This workload is split into two parts:

- the upstream `longhorn` chart configured by `values.yaml` and
  `resources/secrets.sops.yaml`
- the local `resources/` chart that can create:
  - the S3 backup target secret
  - the cluster-wide encryption secret and `longhorn-crypto` storage class
  - the recurring backup job

The built-in Longhorn `StorageClass` is used directly and remains non-default.
Its replica policy can be changed over time for new volumes while keeping the
same storage class name. Existing volumes still need their replica count updated
separately inside Longhorn when the cluster grows.

The repo also defines an opt-in encrypted `StorageClass` named
`longhorn-crypto`. It mirrors the current single-replica `longhorn` class but
uses a cluster-wide LUKS key from `resources/secrets.sops.yaml`. Backups taken
from encrypted Longhorn volumes are encrypted as well. Longhorn requires
`dm_crypt` and `cryptsetup` on worker nodes before provisioning encrypted
volumes.

Existing PVCs do not migrate in place when you change `storageClassName`.
Create a fresh encrypted PVC and move the data at the application layer, or
recreate the workload and restore from an app-native backup.

Recommended first migrations:

1. `infra/postgres` because it holds the shared application database.
2. `infra/authentik` because it stores auth state, templates, and cert material.
3. `infra/grafana` if you want dashboards, datasource config, and admin state encrypted.
4. Leave `infra/prometheus` on plain `longhorn` unless you specifically need encrypted metrics at rest; it has the highest write churn and the lowest sensitivity.

Backups are disabled by default. Longhorn storage works without an S3 target.
When backups are enabled, the upstream Longhorn chart owns the backup target
configuration and the local `resources/` chart owns only the S3 credential
Secret and recurring backup job. The recurring job is added to Longhorn's
`default` group so volumes that do not already have an explicit recurring job
pick it up automatically.

Turn backups on:

1. Edit `workloads/cluster/longhorn/resources/secrets.sops.yaml`.
2. Set `backups.enabled: true`.
3. Add `defaultBackupStore.backupTarget` and, if desired,
   `defaultBackupStore.pollInterval`.
4. Fill in `backupTarget.credentials`.

Turn backups off:

1. Edit `workloads/cluster/longhorn/resources/secrets.sops.yaml`.
2. Set `backups.enabled: false`.
3. Remove the `defaultBackupStore` section.
