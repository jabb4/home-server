# Talos and k8s setup

This directory contains the local bootstrap workflow for the Stratton Talos
cluster.

Current cluster shape:

- `cp-1`: Talos control plane at `10.0.20.11`
- `worker-1`: Talos worker at `10.0.20.21`
- Kubernetes API VIP: `10.0.20.10`
- CNI: `Cilium`
- GitOps controller: `Argo CD`
- cluster app state: `Longhorn`
- large shared file data: static `TrueNAS NFS` shares
- GitOps source: `https://github.com/jabb4/home-server.git` on `targetRevision: v2`

Bootstrap entrypoint:

```bash
just cluster-init
```

Run all commands in this document from:

```bash
cd home-server/machines/stratton/k8s
```

## What this bootstrap does

The `justfile` performs the current day-0 flow:

1. Generate Talos machine configs.
2. Patch configs with the files in `talos/patches/`.
3. Apply configs to the nodes while they are in Talos maintenance mode.
4. Bootstrap the control plane.
5. Pull a local `kubeconfig`.
6. Install `Cilium`.
7. Install `Argo CD`.
8. Apply the root Argo CD application.

After that, Argo CD loads the `application.yaml` file owned by each workload
directory under `workloads/`.

## Prerequisites

You need these local tools on the admin workstation:

- `just`
- `talosctl`
- `kubectl`
- `helm`
- `yq`
- `sops`

The current `just check-tools` recipe validates `talosctl`, `kubectl`, `helm`,
and `yq`. `sops` is also required for secret operations and the initial Argo CD
bootstrap.

You also need:

- L3 reachability from the admin workstation to `10.0.20.0/24`
- the repository checked out locally
- the repo state committed and pushed to branch `v2` before relying on Argo CD
- the SOPS age private key present at the path configured in `.env`
- reachability to each node while it is in Talos maintenance mode
- the cert-manager and Traefik secrets updated in
  `workloads/infra/cert-manager/resources/secrets.sops.yaml` and
  `workloads/infra/traefik/resources/secrets.sops.yaml` before first sync if
  you want working TLS and dashboard auth

Important:

- The final node IPs in `.env` are rendered into the Talos machine configs as
  static network addresses.
- The bootstrap logic assumes the current Services VLAN layout:
  `10.0.20.0/24`, gateway `10.0.20.1`, and DNS `10.0.20.53`.
- The day-0 Cilium and Argo CD Helm versions are read from their committed
  `application.yaml` files, so there is only one chart-version source of truth.
- Argo CD syncs from GitHub, not from your local checkout. Local-only changes
  will not appear in cluster state until they are committed and pushed to `v2`.

## Configure `.env`

Review and update `.env` before bootstrapping:

```env
CLUSTER_NAME=homelab
TALOS_DIR=talos
CONTROLPLANES=cp-1
WORKERS=worker-1
VIP_IP=10.0.20.10
SOPS_AGE_KEY_FILE=/Users/jacob/.config/sops/age/keys.txt
CP_1_IP=10.0.20.11
WORKER_1_IP=10.0.20.21
```

Quick validation:

```bash
just show-vars
test -f "$(grep '^SOPS_AGE_KEY_FILE=' .env | cut -d= -f2-)"
```

Longhorn backups are disabled by default until an S3 target is ready.

## Create the Proxmox VMs

Create one VM per Talos node.

Recommended VM IDs:

- control planes: `2001-2009`
- workers: `2011-2099`

Recommended names:

- control planes: `cp-x`
- workers: `worker-x`

Use this base configuration for each VM:

1. OS image:
   Use a Talos image from [Talos Linux Image Factory](https://factory.talos.dev)
   with:
   - Platform: `Bare Metal`
   - Architecture: `amd64`
   - Extensions: `qemu-guest-agent`, `iscsi-tools`,
     `siderolabs/util-linux-tools`
2. System:
   - Machine: `q35`
   - BIOS: `OVMF`
   - EFI storage: `VM-storage`
   - Pre-enroll keys: unchecked
   - SCSI controller: `VirtIO SCSI`
   - QEMU agent: enabled
3. Disk:
   - Storage: `VM-storage`
   - Size: `100GiB`
   - SSD emulation: enabled
   - Discard: enabled
4. CPU:
   - `4+` cores
5. Memory:
   - `4GB+`
   - Ballooning disabled
6. Network:
   - Bridge: `vmbr0`
   - VLAN tag: `20`
   - Model: `VirtIO`

Additional worker storage:

- every worker should get a second `200GiB` disk dedicated to `Longhorn`
- set the Proxmox disk serial to `<worker-name>-longhorn`
- control planes do not get a Longhorn disk

Current intended nodes:

- `cp-1` on `10.0.20.11`
- `worker-1` on `10.0.20.21`

Make sure each node will be reachable in Talos maintenance mode before
continuing. When booting a stock Talos ISO, that often means a temporary DHCP
lease on the Services VLAN. That current DHCP IP is only for the initial
connection; the final static IP still comes from `.env`.

## Boot the nodes into Talos maintenance mode

1. Attach the Talos ISO to each VM.
2. Boot the VM.
3. Wait for Talos maintenance mode.
4. Confirm each node is reachable in maintenance mode on its current DHCP IP.

Example checks:

```bash
ping <current-dhcp-ip-of-cp-1>
ping <current-dhcp-ip-of-worker-1>
```

## Bootstrap the cluster

For a normal public-repo bootstrap, the full flow is:

```bash
just check-tools
just cluster-init
```

`cluster-init` will prompt for the current IP of every node while it is still
in Talos maintenance mode. Press `Enter` to use the final `.env` IP if the node
is already reachable there. For each node, the flow now waits for Talos to come
back on the final static IP before continuing.

`cluster-init` runs:

```text
render-all -> apply-all-current -> bootstrap -> wait-api -> kubeconfig -> install-cilium -> wait-expected-nodes -> install-argocd -> label-longhorn-workers -> bootstrap-root-app
```

Generated local state is written under:

- `talos/clusterconfig/talosconfig`
- `talos/clusterconfig/kubeconfig`
- `talos/clusterconfig/rendered/*.yaml`



## Verify bootstrap

Use the generated kubeconfig:

```bash
export KUBECONFIG=/Users/jacob/Projects/home-server/machines/stratton/k8s/talos/clusterconfig/kubeconfig
```

Basic checks:

```bash
kubectl get nodes -o wide
kubectl get pods -A
just cilium-status
kubectl -n argocd get applications.argoproj.io
talosctl -n 10.0.20.21 get volumestatus u-longhorn
```

Current GitOps-managed applications expected after bootstrap:

- `cilium`
- `argocd`
- `foundations`
- `longhorn`
- `crowdsec`
- `cert-manager`
- `prometheus`
- `grafana`
- `traefik`
- `homepage`
- `uptime-kuma`

`foundations` creates the shared namespaces and baseline Argo CD projects.
Longhorn storage is active after bootstrap, but Longhorn backups stay disabled
until you explicitly enable them later.
Traefik handles both in-cluster services and the remaining legacy external
services that still live outside Kubernetes.

To enable Longhorn backups later:

1. Edit `workloads/cluster/longhorn/resources/secrets.sops.yaml`.
2. Set `backups.enabled: true`.
3. Add `defaultBackupStore.backupTarget` and, if desired,
   `defaultBackupStore.pollInterval`.
4. Fill in `backupTarget.credentials`.
5. Commit and push the change so Argo CD syncs it.

To disable Longhorn backups again:

1. Edit `workloads/cluster/longhorn/resources/secrets.sops.yaml`.
2. Set `backups.enabled: false`.
3. Remove the `defaultBackupStore` section.
4. Commit and push the change so Argo CD syncs it.

Before the first `cert-manager` and Traefik sync, edit:

```bash
just edit-sops workloads/infra/cert-manager/resources/secrets.sops.yaml
just edit-sops workloads/infra/traefik/resources/secrets.sops.yaml
```

Fill in:

- `cert-manager/resources/secrets.sops.yaml`: `acme.email`
- `cert-manager/resources/secrets.sops.yaml`: `cloudflare.apiToken`
- `traefik/resources/secrets.sops.yaml`: `dashboard.basicAuthUsers`

Traefik is exposed on `10.0.20.80` through Cilium LB IPAM and L2 announcements.
Traefik runs as a `DaemonSet`, so every worker node gets a local ingress pod.
That makes `externalTrafficPolicy: Local` compatible with preserving real
client IPs for CrowdSec while still scaling from one worker to many.
`cert-manager` provisions the wildcard TLS certificates consumed by Traefik in
the `infra` and `apps` namespaces.
Shared Traefik middleware and the external route catalog live in
`workloads/infra/traefik/resources/values.yaml`.
CrowdSec runs in `infra`, tails Traefik logs, and feeds decisions back through
the Traefik bouncer plugin.

## Mount a TrueNAS NFS share into a service

Use static NFS `PersistentVolume` and `PersistentVolumeClaim` objects for large
shared files such as:

- Jellyfin media libraries
- Immich originals or library storage
- Nextcloud document data
- Paperless document archives

Do not put SQLite, PostgreSQL, MariaDB, or general app config data on NFS.
Keep that on `Longhorn`.

1. Create the dataset and NFS export on `TrueNAS`.
   - use a path convention like `k8s/<service>/<share>`
   - export it with access for the Kubernetes worker network
   - use the TrueNAS IP/interface that the workers should use for NFS traffic
2. Add the NFS storage manifests to the consuming workload.
   - keep them with the service, not in a central storage directory
   - for a local chart, place them in `templates/`
   - use explicit names like `<service>-<share>`
3. Mount the resulting PVC into the workload's Deployment or StatefulSet.

Example for a service named `paperless` mounting an NFS share at
`/usr/src/paperless/media`:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: paperless-media
spec:
  capacity:
    storage: 1Ti
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  mountOptions:
    - nfsvers=4.1
  nfs:
    server: TRUENAS_NFS_IP
    path: /mnt/tank/k8s/paperless/media
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: paperless-media
  namespace: apps
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Ti
  storageClassName: ""
  volumeName: paperless-media
```

Then mount the claim in the workload:

```yaml
volumeMounts:
  - name: media
    mountPath: /usr/src/paperless/media

volumes:
  - name: media
    persistentVolumeClaim:
      claimName: paperless-media
```

Recommended conventions:

- use `ReadWriteMany` for shared file-library data
- set `persistentVolumeReclaimPolicy: Retain`
- set `storageClassName: ""` on both the PV and PVC so Kubernetes does not try
  to provision dynamic storage
- keep the PV/PVC names stable so app upgrades do not replace them
- keep NFS manifests in the same workload directory as the consuming service

For services managed from an upstream Helm chart, either:

- use the chart's built-in `existingClaim` or extra-volume support if it has it
- or wrap the service in a local chart so the PV/PVC manifests and the app stay
  in one workload directory

## Add a worker node

Workers are expected to host Longhorn storage by default.

1. Update `.env`:
   - append the node name to `WORKERS`
   - add the new worker IP, for example `WORKER_2_IP=10.0.20.22`
2. Create the Proxmox VM using the same worker baseline as above.
3. Add the dedicated `200GiB` Longhorn disk and set its serial to
   `worker-2-longhorn`.
4. Create `talos/patches/nodes/worker-2.yaml`:

```yaml
apiVersion: v1alpha1
kind: HostnameConfig
hostname: worker-2
auto: off
---
machine:
  kubelet:
    extraMounts:
      - destination: /var/mnt/longhorn
        type: bind
        source: /var/mnt/longhorn
        options:
          - bind
          - rshared
          - rw
---
apiVersion: v1alpha1
kind: UserVolumeConfig
name: longhorn
provisioning:
  diskSelector:
    match: disk.serial == "worker-2-longhorn" && !system_disk
```

5. Boot the VM into Talos maintenance mode and verify it is reachable.
6. Apply and join the node:

```bash
just add-worker worker-2 10.0.20.202
```

`add-worker` applies the node config, joins it to the cluster, and labels the
worker for Longhorn automatically. It waits for Talos on the final static IP
and for the Kubernetes node to become `Ready` before returning. Traefik will
schedule onto the new worker automatically because it runs as a `DaemonSet`.

Verify:

```bash
kubectl get nodes -o wide
just show-longhorn-nodes
kubectl -n longhorn-system get nodes.longhorn.io
```

## Add a control plane node

1. Update `.env`:
   - append the node name to `CONTROLPLANES`
   - add the new control-plane IP, for example `CP_2_IP=10.0.20.12`
2. Create the Proxmox VM using the same control-plane baseline as above.
3. Do not add a Longhorn data disk.
4. Create `talos/patches/nodes/cp-2.yaml`:

```yaml
apiVersion: v1alpha1
kind: HostnameConfig
hostname: cp-2
auto: off
```

5. Boot the VM into Talos maintenance mode and verify it is reachable.
6. Apply and join the node:

```bash
just add-controlplane cp-2 10.0.20.203
```

`add-controlplane` waits for Talos on the final static IP and for the
Kubernetes node to become `Ready` before returning.

Verify:

```bash
kubectl get nodes -o wide
TALOSCONFIG=talos/clusterconfig/talosconfig talosctl get members --nodes 10.0.20.11 --endpoints 10.0.20.11
```

## Current limitations

This bootstrap gets the base cluster online, but it does not yet make the full
infrastructure stack complete. At the time of writing:

- the root Argo CD app only manages the workloads currently committed under
  `workloads/`
- most shared infra services beyond the current committed workloads are not yet
  part of this bootstrap
- default-deny network policies are defined but still disabled in
  `workloads/cluster/foundations/values.yaml`
- booting from a stock Talos ISO still requires temporary maintenance-mode
  reachability before the rendered static machine config is applied

Treat this document as the current cluster bootstrap runbook, not the final
state of the whole homelab platform.
