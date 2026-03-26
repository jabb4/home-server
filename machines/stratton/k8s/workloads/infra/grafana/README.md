# Grafana

This workload installs Grafana as the shared dashboard frontend for the
Stratton cluster.

Current design:

- the upstream-recommended `grafana-community/grafana` chart runs in the `infra` namespace
- Grafana stores its state on the `longhorn` storage class
- the UI is published at `grafana.local.jabbas.dev`
- Prometheus is provisioned automatically as the default datasource
- anonymous viewer access stays enabled so Homepage embeds can keep working

Before first sync, edit if you want to change the generated admin password:

```bash
just edit-sops workloads/infra/grafana/resources/secrets.sops.yaml
```

## Dashboards
In the dashboard dir there are json files for the dashboard. Copy past the contents into the import dashboard in grafana webui
