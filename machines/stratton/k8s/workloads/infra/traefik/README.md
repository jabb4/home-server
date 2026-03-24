# Traefik

This workload installs Traefik as the cluster ingress controller in the
`infra` namespace.

Current design:

- Traefik is exposed by a `LoadBalancer` service
- Cilium LB IPAM + L2 announcements provide the service IP on the services VLAN
- the ingress IP is `10.0.20.80`
- Traefik runs as a `DaemonSet` on worker nodes
- `cert-manager` owns ACME and issues the wildcard certificates Traefik serves
- the dashboard is published at `traefik.local.jabbas.dev` behind basic auth
- CrowdSec protects routes through the Traefik bouncer plugin in `stream` mode
- shared Traefik CRD middleware is managed from `resources/templates/`
- legacy non-Kubernetes services are routed through static `Service` +
  `EndpointSlice` + `IngressRoute` objects from `resources/values.yaml`
- HTTPS legacy backends use route-specific `ServersTransport` objects instead of
  one shared insecure transport

Before first sync, edit:

```bash
just edit-sops workloads/infra/traefik/resources/secrets.sops.yaml
```

`resources/secrets.sops.yaml` now only carries the dashboard basic-auth data.
Cloudflare ACME credentials live with the `cert-manager` workload instead.

Current route model:

- in-cluster apps can keep using standard Kubernetes `Ingress`
- shared security/headers middleware is referenced from the `infra` namespace
- CrowdSec is part of the shared middleware chain for Traefik routes
- external legacy services use Traefik CRDs so HTTPS backends and per-route
  middleware stay explicit
- namespace-local wildcard TLS secrets are issued by `cert-manager` and
  referenced explicitly by `Ingress` and `IngressRoute` objects

Middleware notes:

- For standard Kubernetes `Ingress`, Traefik middleware annotations use the
  flattened format `<middleware-namespace>-<middleware-name>@kubernetescrd`.
- Example:

```yaml
traefik.ingress.kubernetes.io/router.middlewares: infra-ui-default@kubernetescrd
```

- Multiple middleware references in the same `Ingress` annotation are separated
  with commas.
- Example:

```yaml
traefik.ingress.kubernetes.io/router.middlewares: infra-ui-default@kubernetescrd,infra-some-other@kubernetescrd
```

- For Traefik `IngressRoute` CRDs, do not use the flattened annotation syntax.
  Reference middleware `name` and `namespace` separately in the route spec.

Not migrated yet:

- Authentik forward-auth is scaffolded but disabled by default
- Cloudflare Warp is intentionally not wired into the Kubernetes Traefik
  deployment
