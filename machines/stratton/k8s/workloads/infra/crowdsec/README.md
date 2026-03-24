# CrowdSec

This workload deploys CrowdSec into the `infra` namespace to protect Traefik.

Current design:

- the official `crowdsec/crowdsec` chart runs the LAPI and agent
- the agent tails Traefik pod logs in `infra`
- LAPI stores its state on `Longhorn`
- a repo-local secret provides the shared Traefik bouncer key
- Traefik uses the CrowdSec bouncer plugin in `stream` mode

The bouncer key lives in:

```bash
just edit-sops workloads/infra/crowdsec/resources/secrets.sops.yaml
```
