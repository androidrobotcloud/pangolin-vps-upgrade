#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <spec-file> <expected-version>" >&2
  exit 1
fi

SPEC_FILE="$1"
EXPECTED_VERSION="$2"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

remote() {
  ssh "$SSH_TARGET" "$@"
}

# Derive the edition tag prefix from the current compose image so the expected
# target preserves the running edition (e.g. "ee-" stays "ee-").
compose_image="$(remote "cd '$STACK_PATH' && awk '/image:.*fosrl\\/pangolin:/ {print \$2; exit}' docker-compose.yml")"
current_tag="${compose_image##*:}"
edition_prefix="${current_tag%%[0-9]*}"
expected_image="${PANGOLIN_IMAGE_REPO}:${edition_prefix}${EXPECTED_VERSION}"

runtime_image="$(remote "docker inspect pangolin --format '{{.Config.Image}}'")"

if [[ "$compose_image" != "$expected_image" ]]; then
  echo "[fail] Compose image mismatch: expected $expected_image got $compose_image" >&2
  exit 1
fi

if [[ "$runtime_image" != "$expected_image" ]]; then
  echo "[fail] Runtime image mismatch: expected $expected_image got $runtime_image" >&2
  exit 1
fi

./bin/verify-vm890-runtime.sh "$SPEC_FILE" >/dev/null
printf '[pass] Pangolin compose and runtime image both match %s\n' "$expected_image"
