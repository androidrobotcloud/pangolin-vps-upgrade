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

current_compose_image="$(ssh "$SSH_TARGET" "cd '$STACK_PATH' && awk '/image:.*fosrl\\/pangolin:/ {print \$2; exit}' docker-compose.yml")"
if [[ -z "$current_compose_image" ]]; then
  echo "[fail] Could not resolve current Pangolin compose image on $SSH_TARGET" >&2
  exit 1
fi

current_tag="${current_compose_image##*:}"
edition_prefix="${current_tag%%[0-9]*}"
target_image="${PANGOLIN_IMAGE_REPO}:${edition_prefix}${TARGET_VERSION}"

printf '%s\n' "$target_image"
