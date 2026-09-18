#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <spec-file> <target-label>" >&2
  exit 1
fi

SPEC_FILE="$1"
TARGET_LABEL="$2"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

remote() {
  ssh "$SSH_TARGET" "$@"
}

stamp="$(date +%Y%m%d-%H%M%S)"
backup_name="${stamp}-pre-${TARGET_LABEL}.tar.gz"

remote "mkdir -p '$BACKUP_DIR'"

# Build the list of paths to archive. Always include docker-compose.yml and
# config/. Include app-data/ only when it exists on the host so the backup is
# forward-compatible with deployments that use a separate app-data directory
# without breaking on vm890-style layouts where all state lives under config/.
archive_items="$(remote "cd '$STACK_PATH' && items='docker-compose.yml config'; [ -d app-data ] && items=\"\$items app-data\"; echo \$items")"

remote "docker run --rm -v '$STACK_PATH:/src:ro' -v '$BACKUP_DIR:/backups' alpine:3.20 sh -lc 'cd /src && tar -czpf /backups/$backup_name $archive_items'"
remote "test -f '$BACKUP_DIR/$backup_name'"

printf '%s\n' "$backup_name"
