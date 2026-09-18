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

# Resolve the expected image through the same canonical edition-preserving helper\n# used by the mutation and registry-preflight paths.\nexpected_image="$(./bin/resolve-pangolin-target-image.sh "$SPEC_FILE" "$EXPECTED_VERSION")"\n
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
