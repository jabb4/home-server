#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

cd "${repo_root}"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "Missing required tool: gitleaks" >&2
  exit 1
fi

gitleaks git . \
  --config .gitleaks.toml \
  --no-banner \
  --redact
