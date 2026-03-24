# Security

## Secret Leak Prevention

This repository uses `gitleaks` in GitHub Actions to scan for leaked
credentials on:

- every push
- every pull request
- manual workflow dispatches

The workflow lives in
[`/.github/workflows/secret-scan.yml`](.github/workflows/secret-scan.yml)
and uses the repo-specific allowlist in
[`/.gitleaks.toml`](.gitleaks.toml).

For the same scan locally, run:

```bash
./scripts/scan-secrets.sh
```

The allowlist is intentionally narrow. It only permits known placeholders and
documentation examples that are not real credentials.

Known historical findings that still exist in Git history are tracked in
[`/.gitleaksignore`](.gitleaksignore). This keeps CI enforceable for new pushes
without pretending the old history is clean. Rotate and remove ignored
fingerprints once the underlying history is cleaned up.

## GitHub Settings

GitHub secret scanning alerts and push protection are not controlled from files
in this repository. Enable them in the repository settings so supported secrets
are blocked before they land on GitHub.

If this repository is later moved under a GitHub organization account,
`gitleaks-action` may also require a `GITLEAKS_LICENSE` repository secret. See
the upstream action documentation for the current requirement.
