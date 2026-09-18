#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <backup-tarball>" >&2
  exit 1
fi

BACKUP_TARBALL="$1"

if [[ ! -f "$BACKUP_TARBALL" ]]; then
  echo "[fail] Backup tarball not found: $BACKUP_TARBALL" >&2
  exit 1
fi

echo "== pangolin backup verify =="
echo "Tarball: $BACKUP_TARBALL"
echo "Size: $(stat -f%z "$BACKUP_TARBALL" 2>/dev/null || stat --format=%s "$BACKUP_TARBALL" 2>/dev/null || echo unknown) bytes"

# Critical paths that must exist in the archive for a complete vm890 recovery.
# On vm890 all persistent state lives under config/ (no separate app-data dir):
#   - db.sqlite  (Pangolin database)
#   - key        (Pangolin encryption key)
#   - letsencrypt/acme.json  (TLS certificates)
#   - traefik/traefik_config.yml  (reverse proxy config + Badger plugin version)
#   - config.yml  (Pangolin main config)
REQUIRED_PATHS=(
  "docker-compose.yml"
  "config/db/db.sqlite"
  "config/key"
  "config/letsencrypt/acme.json"
  "config/traefik/traefik_config.yml"
  "config/config.yml"
)

ARCHIVE_CONTENTS="$(tar -tzf "$BACKUP_TARBALL")"

missing=0
for path in "${REQUIRED_PATHS[@]}"; do
  if grep -qE "(^|/|\\.\\/)(${path})$|(^|/|\\.\\/)(${path})/" <<<"$ARCHIVE_CONTENTS"; then
    echo "[present] $path"
  else
    echo "[MISSING] $path" >&2
    missing=$((missing + 1))
  fi
done

if [[ $missing -gt 0 ]]; then
  echo "[fail] Backup is missing $missing required path(s). Refusing to proceed." >&2
  exit 1
fi

echo "[pass] Backup contains all ${#REQUIRED_PATHS[@]} required paths"
