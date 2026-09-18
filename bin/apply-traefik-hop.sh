#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <spec-file> <target-version>" >&2
  exit 1
fi

SPEC_FILE="$1"
TARGET_VERSION="$2"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

remote() {
  ssh "$SSH_TARGET" "$@"
}

current_compose_image="$(remote "cd '$STACK_PATH' && awk '/image:.*traefik:/ {print \$2; exit}' docker-compose.yml")"
current_runtime_image="$(remote "docker inspect traefik --format '{{.Config.Image}}'")"
target_image="${TRAEFIK_IMAGE_REPO}:${TARGET_VERSION}"

current_runtime_version="${current_runtime_image##*:}"

python3 - "$current_runtime_version" "$TARGET_VERSION" <<'PY'
import re
import sys

def parse(v: str):
    return tuple(int(p) for p in re.findall(r"\d+", v)[:3])

current = parse(sys.argv[1])
target = parse(sys.argv[2])
if current > target:
    print(f"[fail] Refusing downgrade: current version {sys.argv[1]} is newer than target {sys.argv[2]}", file=sys.stderr)
    raise SystemExit(1)
PY

if [[ "$current_runtime_image" == "$target_image" ]]; then
  echo "[pass] Traefik already at $target_image"
  exit 0
fi

remote "docker run --rm -v '$STACK_PATH:/work' alpine:3.20 sh -lc \"sed -i 's#${current_compose_image}#${target_image}#' /work/docker-compose.yml\""
remote "cd '$STACK_PATH' && docker compose down"
remote "cd '$STACK_PATH' && docker compose pull traefik"
remote "cd '$STACK_PATH' && docker compose up -d"

printf '[pass] Applied Traefik hop to %s\n' "$TARGET_VERSION"
