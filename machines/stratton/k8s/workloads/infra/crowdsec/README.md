# CrowdSec

This workload deploys CrowdSec into the dedicated `crowdsec` namespace to
protect Traefik.

Current design:

- the official `crowdsec/crowdsec` chart runs the LAPI and agent
- the agent reads Traefik pod logs from the Kubernetes API instead of mounting
  host `/var/log`
- LAPI stores its state on `Longhorn`
- a repo-local secret provides the shared Traefik bouncer key
- Traefik uses the CrowdSec bouncer plugin in `stream` mode
- `externalTrafficPolicy: Local` on Traefik preserves the real client IP, so
  CrowdSec decisions key off the caller instead of the ingress node IP

The bouncer key lives in:

```bash
just edit-sops workloads/infra/crowdsec/resources/secrets.sops.yaml
```
