#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <spec-file>" >&2
  exit 1
fi

SPEC_FILE="$1"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[fail] Missing required command: $1" >&2
    exit 1
  }
}

need_cmd ssh

remote() {
  ssh "$SSH_TARGET" "$@"
}

echo "== vm890 profile check =="

ACTUAL_HOSTNAME="$(remote "hostname")"
if [[ "$ACTUAL_HOSTNAME" != "$EXPECTED_HOSTNAME" ]]; then
  echo "[fail] Hostname mismatch: expected $EXPECTED_HOSTNAME got $ACTUAL_HOSTNAME" >&2
  exit 1
fi
echo "[pass] Hostname matches: $ACTUAL_HOSTNAME"

if ! remote "test -d '$STACK_PATH'"; then
  echo "[fail] Stack path missing: $STACK_PATH" >&2
  exit 1
fi
echo "[pass] Stack path exists: $STACK_PATH"

COMPOSE_SERVICES="$(remote "cd '$STACK_PATH' && docker compose config --services")"
for svc in $EXPECTED_SERVICES; do
  if ! grep -qx "$svc" <<<"$COMPOSE_SERVICES"; then
    echo "[fail] Missing compose service: $svc" >&2
    exit 1
  fi
done
echo "[pass] Required compose services present: $EXPECTED_SERVICES"

COMPOSE_IMAGES="$(remote "cd '$STACK_PATH' && docker compose images")"
for image in "$EXPECTED_PANGOLIN_IMAGE" "$EXPECTED_GERBIL_IMAGE" "$EXPECTED_TRAEFIK_IMAGE" "$EXPECTED_CROWDSEC_IMAGE"; do
  repo="${image%:*}"
  tag="${image##*:}"
  if ! grep -Eq "[[:space:]]${repo//\//\\/}[[:space:]]+${tag}[[:space:]]" <<<"$COMPOSE_IMAGES"; then
    echo "[fail] Expected image not found: $image" >&2
    exit 1
  fi
done
echo "[pass] Expected image tags found"

DASHBOARD_URL_LINE="$(remote "cd '$STACK_PATH' && awk -F'\"' '/dashboard_url:/ {print \$2; exit}' config/config.yml")"
if [[ "$DASHBOARD_URL_LINE" != "$EXPECTED_DASHBOARD_URL" ]]; then
  echo "[fail] Dashboard URL mismatch: expected $EXPECTED_DASHBOARD_URL got $DASHBOARD_URL_LINE" >&2
  exit 1
fi
echo "[pass] Dashboard URL matches runtime profile"

BASE_DOMAIN_LINE="$(remote "cd '$STACK_PATH' && awk -F'\"' '/base_domain:/ {print \$2; exit}' config/config.yml")"
if [[ "$BASE_DOMAIN_LINE" != "$EXPECTED_BASE_DOMAIN" ]]; then
  echo "[fail] Base domain mismatch: expected $EXPECTED_BASE_DOMAIN got $BASE_DOMAIN_LINE" >&2
  exit 1
fi
echo "[pass] Base domain matches runtime profile"

NETWORK_MODE_LINE="$(remote "cd '$STACK_PATH' && awk '/network_mode:/ {print \$2; exit}' docker-compose.yml")"
if [[ "$NETWORK_MODE_LINE" != "service:gerbil" ]]; then
  echo "[fail] Traefik network mode mismatch: expected service:gerbil got $NETWORK_MODE_LINE" >&2
  exit 1
fi
echo "[pass] Traefik network mode matches expected topology"
