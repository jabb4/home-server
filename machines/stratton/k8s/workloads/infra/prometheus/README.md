# Prometheus

This workload installs Prometheus as the shared metrics backend for the
Stratton cluster.

Current design:

- the official `prometheus-community/prometheus` chart runs in the `infra`
  namespace
- Prometheus stores time series on the `longhorn` storage class
- the UI is published at `prometheus.local.jabbas.dev`
- Grafana consumes Prometheus as its default datasource
- a static scrape job keeps scraping the existing Proxmox node exporter during
  the migration from legacy Docker services

Current scrape model:

- built-in cluster scrape jobs from the chart stay enabled
- Alertmanager and Pushgateway are disabled for now to keep the footprint lean
- the legacy Proxmox node exporter is scraped directly at `192.168.20.2:9100`
  instead of through Traefik
