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

current_compose_image="$(remote "cd '$STACK_PATH' && awk '/image:.*fosrl\\/pangolin:/ {print \$2; exit}' docker-compose.yml")"
current_runtime_image="$(remote "docker inspect pangolin --format '{{.Config.Image}}'")"

# Derive the edition tag prefix (e.g. "ee-" or "") from the CURRENT image so the
# target preserves the running edition. This makes it impossible to accidentally
# convert ee-1.21.1 -> 1.22.2 (Community) or vice-versa.
current_tag="${current_compose_image##*:}"
edition_prefix="${current_tag%%[0-9]*}"
target_image="${PANGOLIN_IMAGE_REPO}:${edition_prefix}${TARGET_VERSION}"

current_runtime_version="${current_runtime_image##*:}"

python3 - "$current_runtime_version" "$TARGET_VERSION" "$edition_prefix" <<'PY'
import sys
import re

def parse(v: str, prefix: str):
    if prefix and v.startswith(prefix):
        v = v[len(prefix):]
    v = v.lstrip("v")
    nums = re.findall(r"\d+", v)
    while len(nums) < 3:
        nums.append(0)
    return tuple(int(p) for p in nums[:3])

current = parse(sys.argv[1], sys.argv[3])
target = parse(sys.argv[2], sys.argv[3])
if current > target:
    print(f"[fail] Refusing downgrade: current version {sys.argv[1]} is newer than target {sys.argv[2]}", file=sys.stderr)
    raise SystemExit(1)
PY

if [[ "$current_runtime_image" == "$target_image" ]]; then
  echo "[pass] Pangolin already at $target_image"
  exit 0
fi

remote "docker run --rm -v '$STACK_PATH:/work' alpine:3.20 sh -lc \"sed -i 's#${current_compose_image}#${target_image}#' /work/docker-compose.yml\""
remote "cd '$STACK_PATH' && docker compose down"
remote "cd '$STACK_PATH' && docker compose pull pangolin"
remote "cd '$STACK_PATH' && docker compose up -d"

printf '[pass] Applied Pangolin hop to %s\n' "$target_image"
