#!/usr/bin/env bash

set -euo pipefail

# Verifies a vm890 Pangolin backup archive contains all critical recovery paths.
#
# The backup lives remotely on the target host in production, but the verifier
# also supports a LOCAL path for testing. Resolution order:
#   1. If <backup-path> exists as a local file, verify it locally.
#   2. Otherwise, source the spec and verify over SSH at the remote path.
# This keeps a single canonical definition of "valid backup" usable both in the
# execution orchestrator (remote) and in tests (local).

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file|-> <backup-path>" >&2
  echo "       $0 <backup-path>                 (local-only, no spec)" >&2
  exit 1
fi

# Determine whether we have a spec file (2 args) or local-only (1-remaining arg).
if [[ $# -eq 2 ]]; then
  SPEC_FILE="$1"
  BACKUP_PATH="$2"
else
  SPEC_FILE=""
  BACKUP_PATH="$1"
fi

# Remote helper (only defined when a spec is supplied).
if [[ -n "$SPEC_FILE" ]]; then
  if [[ ! -f "$SPEC_FILE" ]]; then
    echo "[fail] Missing spec file: $SPEC_FILE" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$SPEC_FILE"

  remote() {
    ssh "$SSH_TARGET" "$@"
  }

  # If no absolute path was given, resolve relative to BACKUP_DIR on the host.
  if [[ "$BACKUP_PATH" != /* ]]; then
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_PATH}"
  fi
fi

echo "== pangolin backup verify =="

# Decide local vs remote based on whether the path exists on the local filesystem.
if [[ -f "$BACKUP_PATH" ]]; then
  echo "Mode: local"
  echo "Tarball: $BACKUP_PATH"
  echo "Size: $(stat -f%z "$BACKUP_PATH" 2>/dev/null || stat --format=%s "$BACKUP_PATH" 2>/dev/null || echo unknown) bytes"
  ARCHIVE_CONTENTS="$(tar -tzf "$BACKUP_PATH")"
else
  if [[ -z "$SPEC_FILE" ]]; then
    echo "[fail] Backup tarball not found locally and no spec given for remote check: $BACKUP_PATH" >&2
    exit 1
  fi
  echo "Host: $SSH_TARGET"
  echo "Tarball: $BACKUP_PATH"
  remote_size="$(remote "stat -c %s '$BACKUP_PATH' 2>/dev/null || stat -f%z '$BACKUP_PATH' 2>/dev/null || echo unknown")"
  echo "Size: $remote_size bytes"
  if [[ "$remote_size" == "0" || "$remote_size" == "unknown" ]]; then
    echo "[fail] Backup tarball missing or unreadable on remote host: $BACKUP_PATH" >&2
    exit 1
  fi
  ARCHIVE_CONTENTS="$(remote "tar -tzf '$BACKUP_PATH'")"
fi

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

missing=0
for path in "${REQUIRED_PATHS[@]}"; do
  if grep -qE "(^|/)(${path})$" <<<"$ARCHIVE_CONTENTS"; then
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
