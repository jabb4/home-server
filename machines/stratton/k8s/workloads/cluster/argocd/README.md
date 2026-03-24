# Argo CD

This directory holds the Git-managed values for the upstream Argo CD Helm chart.

Bootstrap and steady-state use the same values file:

- bootstrap: `just install-argocd`
- GitOps: the `argocd` Argo CD application in `application.yaml`

File:

- `application.yaml`: Argo CD workload definition for this service
- `values.yaml`: pinned Argo CD chart values, including the repo-server
  `helm-secrets`/`sops`/`age` bootstrap
