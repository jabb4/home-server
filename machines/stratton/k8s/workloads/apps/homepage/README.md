# Homepage

This chart deploys the Homepage dashboard into the `apps` namespace.

## Secret Flow

- Non-sensitive defaults stay in `values.yaml`.
- Sensitive credentials and API keys live in `secrets.sops.yaml`.
- Argo CD reads that encrypted values file through `helm-secrets`.
- The chart renders a Kubernetes `Secret` named `homepage-secrets` and injects it with `envFrom`.

## Files

- `values.yaml`: non-sensitive chart defaults
- `secrets.example.yaml`: plaintext schema for the secret values file
- `secrets.sops.yaml`: encrypted secret values consumed by Argo CD
- `files/config/`: Homepage config files mounted as a ConfigMap

## Editing Secrets

1. Edit the encrypted file with `just edit-sops workloads/apps/homepage/secrets.sops.yaml`.
2. Keep the keys aligned with the placeholders used in `files/config/`.
3. Re-sync the `homepage` Argo CD application after the change is committed.

If you need to inspect the decrypted values without editing, use:

- `just decrypt-sops workloads/apps/homepage/secrets.sops.yaml`

If you need to create a fresh encrypted file from the schema:

1. `cp workloads/apps/homepage/secrets.example.yaml workloads/apps/homepage/secrets.sops.yaml`
2. `just encrypt-sops workloads/apps/homepage/secrets.sops.yaml`
