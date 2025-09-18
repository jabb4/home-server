#!/bin/bash
set -euo pipefail

# === Config (use .env or export here) ===
export AWS_ACCESS_KEY_ID="YOUR_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET"
export RESTIC_REPOSITORY="s3:s3.amazonaws.com/your-bucket-name"
export RESTIC_PASSWORD="your-strong-passphrase"

# === Step 1: Run Gitea dump inside container ===
# Always overwrite the same file instead of stacking dumps
docker exec gitea-server \
  /usr/local/bin/gitea dump \
  -c /data/gitea/conf/app.ini \
  -f /data/gitea-backup.zip

# On the host, this file lives at: ./data/gitea-backup.zip
DUMP_FILE="./gitea/gitea-backup.zip"

# === Step 2: Backup with Restic ===
restic backup "$DUMP_FILE"

# === Step 3: Apply retention policy on S3 ===
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune

# === Step 4: Cleanup local dump ===
rm -f "$DUMP_FILE"
