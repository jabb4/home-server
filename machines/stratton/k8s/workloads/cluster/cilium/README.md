# Cilium

This directory holds the Git-managed Cilium workload for the cluster.

Current design:

- the upstream `cilium/cilium` chart installs Cilium itself
- the local `resources/` chart creates cluster-specific Cilium CRs such as the
  `LoadBalancer` IP pool and L2 announcement policy used for bare-metal service
  exposure
- the Traefik ingress VIP is announced from worker nodes that can host the
  Traefik `DaemonSet`
- bootstrap and steady-state still use the same upstream values file

File:

- `application.yaml`: Argo CD workload definition for this service
- `values.yaml`: pinned upstream Cilium chart values for this cluster
- `resources/`: repo-owned Cilium CRs for this cluster
