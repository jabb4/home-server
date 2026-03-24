# cert-manager

This workload installs cert-manager as the shared certificate controller for
the cluster.

Current design:

- the official `jetstack/cert-manager` chart runs in the `cert-manager`
  namespace
- a Cloudflare-backed `ClusterIssuer` provides ACME DNS-01 validation
- wildcard certificates are issued for the `infra` and `apps` namespaces
- Traefik consumes namespace-local TLS secrets instead of managing ACME itself

Before first sync, edit:

```bash
just edit-sops workloads/infra/cert-manager/resources/secrets.sops.yaml
```

Fill in:

- `acme.email`
- `cloudflare.apiToken`
