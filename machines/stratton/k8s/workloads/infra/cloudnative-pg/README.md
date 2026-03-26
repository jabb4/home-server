# CloudNativePG

This workload installs the `CloudNativePG` operator into the `cnpg-system`
namespace.

The operator is the control plane for PostgreSQL clusters managed in Git from
this repo. The first shared database workload lives in `../postgres/`.

Files:

- `application.yaml`: Argo CD application for the upstream operator chart
- `values.yaml`: pinned operator chart values for this cluster
