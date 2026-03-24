# Cluster workloads

This directory contains cluster-core workloads and cluster scaffolding.

Use `cluster/` for things that make the cluster exist or define its trust
boundaries, for example:

- network and cluster controllers such as `Cilium`
- service IP allocation and L2 announcement resources owned by `Cilium`
- the GitOps controller itself, such as `Argo CD`
- the cluster storage subsystem, such as `Longhorn`
- shared namespaces, Argo projects, and baseline policies in `foundations`

These workloads are different from `infra/`, which should contain shared
services that run on top of the cluster rather than define the cluster itself.
