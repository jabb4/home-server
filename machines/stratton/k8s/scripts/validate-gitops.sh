#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
k8s_dir="$(cd "${script_dir}/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
schema_files=("${k8s_dir}/bootstrap/root-application.yaml" "${k8s_dir}/bootstrap/appprojects.yaml")
crowdsec_resources_chart="${k8s_dir}/workloads/infra/crowdsec/resources"
crowdsec_chart_values="${k8s_dir}/workloads/infra/crowdsec/values.yaml"
crowdsec_chart_version="$(yq '.spec.sources[0].targetRevision' "${k8s_dir}/workloads/infra/crowdsec/application.yaml")"
cnpg_chart_values="${k8s_dir}/workloads/infra/cloudnative-pg/values.yaml"
cnpg_chart_version="$(yq '.spec.sources[0].targetRevision' "${k8s_dir}/workloads/infra/cloudnative-pg/application.yaml")"
cert_manager_resources_chart="${k8s_dir}/workloads/infra/cert-manager/resources"
cert_manager_chart_values="${k8s_dir}/workloads/infra/cert-manager/values.yaml"
cert_manager_chart_version="$(yq '.spec.sources[0].targetRevision' "${k8s_dir}/workloads/infra/cert-manager/application.yaml")"
authentik_chart="${k8s_dir}/workloads/infra/authentik/resources"
authentik_chart_values="${authentik_chart}/values.yaml"
authentik_chart_version="$(yq -r '.dependencies[] | select(.name == "authentik") | .version' "${authentik_chart}/Chart.yaml")"
postgres_chart="${k8s_dir}/workloads/infra/postgres"
traefik_resources_chart="${k8s_dir}/workloads/infra/traefik/resources"
traefik_chart_values="${k8s_dir}/workloads/infra/traefik/values.yaml"
traefik_chart_version="$(yq '.spec.sources[0].targetRevision' "${k8s_dir}/workloads/infra/traefik/application.yaml")"
cilium_chart_values="${k8s_dir}/workloads/cluster/cilium/values.yaml"
cilium_chart_version="$(yq '.spec.sources[0].targetRevision' "${k8s_dir}/workloads/cluster/cilium/application.yaml")"
longhorn_chart_values="${k8s_dir}/workloads/cluster/longhorn/values.yaml"
longhorn_chart_version="$(yq '.spec.sources[0].targetRevision' "${k8s_dir}/workloads/cluster/longhorn/application.yaml")"

render_chart() {
  local name="$1"
  local chart_dir="$2"
  local values_file="$3"
  local output_file="$4"
  shift 4

  helm lint "${chart_dir}" --values "${values_file}" "$@"
  helm template "${name}" "${chart_dir}" --values "${values_file}" "$@" > "${output_file}"
}

yq eval '.kind' "${k8s_dir}/bootstrap/root-application.yaml" >/dev/null

while IFS= read -r application_file; do
  yq eval '.kind' "${application_file}" >/dev/null
  schema_files+=("${application_file}")
done < <(find "${k8s_dir}/workloads" -name application.yaml | sort)

while IFS= read -r chart_file; do
  chart_dir="$(dirname "${chart_file}")"
  values_file="${chart_dir}/values.yaml"
  output_file="${tmp_dir}/$(echo "${chart_dir#${k8s_dir}/}" | tr '/' '_').yaml"

  if [ "${chart_dir}" = "${traefik_resources_chart}" ] || [ "${chart_dir}" = "${crowdsec_resources_chart}" ] || [ "${chart_dir}" = "${cert_manager_resources_chart}" ] || [ "${chart_dir}" = "${postgres_chart}" ] || [ "${chart_dir}" = "${authentik_chart}" ]; then
    continue
  fi

  if [ ! -f "${values_file}" ]; then
    echo "Missing values.yaml for chart ${chart_dir}" >&2
    exit 1
  fi

  render_chart "$(basename "${chart_dir}")" "${chart_dir}" "${values_file}" "${output_file}"
  schema_files+=("${output_file}")
done < <(find "${k8s_dir}/workloads" -name Chart.yaml | sort)

if [ -f "${crowdsec_resources_chart}/Chart.yaml" ]; then
  output_file="${tmp_dir}/workloads_infra_crowdsec_resources.yaml"
  render_chart "crowdsec-resources" "${crowdsec_resources_chart}" "${crowdsec_resources_chart}/values.yaml" "${output_file}" \
    --set crowdsecBouncer.lapiKey=dummy-bouncer-key
  schema_files+=("${output_file}")
fi

if [ -f "${postgres_chart}/Chart.yaml" ]; then
  output_file="${tmp_dir}/workloads_infra_postgres.yaml"
  postgres_render_args=()
  while IFS= read -r app_name; do
    postgres_render_args+=(--set "appSecrets.${app_name}.password=dummy-password")
  done < <(yq -r '.apps[].name' "${postgres_chart}/values.yaml")
  render_chart "postgres" "${postgres_chart}" "${postgres_chart}/values.yaml" "${output_file}" "${postgres_render_args[@]}"
  schema_files+=("${output_file}")
fi

if [ -f "${cert_manager_resources_chart}/Chart.yaml" ]; then
  output_file="${tmp_dir}/workloads_infra_cert_manager_resources.yaml"
  render_chart "cert-manager-resources" "${cert_manager_resources_chart}" "${cert_manager_resources_chart}/values.yaml" "${output_file}" \
    --set acme.email=dummy@example.com \
    --set cloudflare.apiToken=dummy-cloudflare-token
  schema_files+=("${output_file}")
fi

if [ -f "${traefik_resources_chart}/Chart.yaml" ]; then
  output_file="${tmp_dir}/workloads_infra_traefik_resources.yaml"
  render_chart "traefik-resources" "${traefik_resources_chart}" "${traefik_resources_chart}/values.yaml" "${output_file}" \
    --set crowdsecBouncer.lapiKey=dummy-bouncer-key \
    --set dashboard.basicAuthUsers='admin:$apr1$dummy$dummy'
  schema_files+=("${output_file}")
fi

helm repo add crowdsec https://crowdsecurity.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update crowdsec >/dev/null 2>&1 || true

if helm show chart crowdsec/crowdsec --version "${crowdsec_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_infra_crowdsec_upstream.yaml"
  helm template crowdsec crowdsec/crowdsec --version "${crowdsec_chart_version}" \
    --values "${crowdsec_chart_values}" > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream CrowdSec chart validation; chart repo unavailable" >&2
fi

helm repo add cnpg https://cloudnative-pg.github.io/charts >/dev/null 2>&1 || true
helm repo update cnpg >/dev/null 2>&1 || true

if helm show chart cnpg/cloudnative-pg --version "${cnpg_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_infra_cloudnative_pg_upstream.yaml"
  helm template cloudnative-pg cnpg/cloudnative-pg --version "${cnpg_chart_version}" \
    --namespace cnpg-system \
    --values "${cnpg_chart_values}" > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream CloudNativePG chart validation; chart repo unavailable" >&2
fi

helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo update jetstack >/dev/null 2>&1 || true

if helm show chart jetstack/cert-manager --version "${cert_manager_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_infra_cert_manager_upstream.yaml"
  helm template cert-manager jetstack/cert-manager --version "${cert_manager_chart_version}" \
    --namespace cert-manager \
    --values "${cert_manager_chart_values}" > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream cert-manager chart validation; chart repo unavailable" >&2
fi

helm repo add authentik https://charts.goauthentik.io >/dev/null 2>&1 || true
helm repo update authentik >/dev/null 2>&1 || true

if helm show chart authentik/authentik --version "${authentik_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_infra_authentik_upstream.yaml"
  authentik_upstream_values="${tmp_dir}/workloads_infra_authentik_upstream_values.yaml"
  yq eval '.upstream' "${authentik_chart_values}" > "${authentik_upstream_values}"
  helm template authentik authentik/authentik --version "${authentik_chart_version}" \
    --namespace infra \
    --values "${authentik_upstream_values}" \
    --set authentik.secret_key=dummy-secret-key > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream authentik chart validation; chart repo unavailable" >&2
fi

helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
helm repo update traefik >/dev/null 2>&1 || true

if helm show chart traefik/traefik --version "${traefik_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_infra_traefik_upstream.yaml"
  helm template traefik traefik/traefik --version "${traefik_chart_version}" \
    --values "${traefik_chart_values}" \
    --set certificatesResolvers.cloudflare.acme.email=dummy@example.com > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream Traefik chart validation; chart repo unavailable" >&2
fi

helm repo add cilium https://helm.cilium.io/ >/dev/null 2>&1 || true
helm repo update cilium >/dev/null 2>&1 || true

if helm show chart cilium/cilium --version "${cilium_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_cluster_cilium_upstream.yaml"
  helm template cilium cilium/cilium --version "${cilium_chart_version}" \
    --namespace kube-system \
    --values "${cilium_chart_values}" > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream Cilium chart validation; chart repo unavailable" >&2
fi

helm repo add longhorn https://charts.longhorn.io >/dev/null 2>&1 || true
helm repo update longhorn >/dev/null 2>&1 || true

if helm show chart longhorn/longhorn --version "${longhorn_chart_version}" >/dev/null 2>&1; then
  output_file="${tmp_dir}/workloads_cluster_longhorn_upstream.yaml"
  helm template longhorn longhorn/longhorn --version "${longhorn_chart_version}" \
    --namespace longhorn-system \
    --values "${longhorn_chart_values}" > "${output_file}"
  schema_files+=("${output_file}")
else
  echo "Skipping upstream Longhorn chart validation; chart repo unavailable" >&2
fi

longhorn_resources_chart="${k8s_dir}/workloads/cluster/longhorn/resources"
if [ -f "${longhorn_resources_chart}/Chart.yaml" ]; then
  output_file="${tmp_dir}/workloads_cluster_longhorn_resources_backups_enabled.yaml"
  render_chart "longhorn-resources-backups" "${longhorn_resources_chart}" "${longhorn_resources_chart}/values.yaml" "${output_file}" \
    --set backups.enabled=true \
    --set backupTarget.secretName=longhorn-s3-backup-target \
    --set backupTarget.credentials.accessKeyId=dummy-access-key \
    --set backupTarget.credentials.secretAccessKey=dummy-secret-key \
    --set backupTarget.credentials.endpoint=https://s3.example.invalid \
    --set defaultBackupStore.backupTarget=s3://dummy-bucket@eu-central-1/ \
    --set defaultBackupStore.pollInterval=300
  schema_files+=("${output_file}")
fi

while IFS= read -r values_file; do
  yq eval '.' "${values_file}" >/dev/null
done < <(find "${k8s_dir}/workloads" -name values.yaml | sort)

while IFS= read -r encrypted_values_file; do
  yq eval '.' "${encrypted_values_file}" >/dev/null
done < <(find "${k8s_dir}/workloads" \( -name '*.sops.yaml' -o -name '*.sops.yml' \) | sort)

if command -v kubeconform >/dev/null; then
  kubeconform -strict -summary -ignore-missing-schemas "${schema_files[@]}"
else
  echo "kubeconform not found; skipping schema validation" >&2
fi

echo "GitOps validation passed"
