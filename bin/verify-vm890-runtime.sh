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
need_cmd curl

remote() {
  ssh "$SSH_TARGET" "$@"
}

echo "== vm890 runtime verify =="

HEALTH_RESPONSE="$(remote "docker exec pangolin curl -fsS http://localhost:3001/api/v1/")"
if [[ "$HEALTH_RESPONSE" != *"Healthy"* ]]; then
  echo "[fail] Pangolin internal health did not return Healthy" >&2
  exit 1
fi
echo "[pass] Pangolin internal health is healthy"

HTTP_HEADERS=""
for _attempt in 1 2 3 4 5 6; do
  if HTTP_HEADERS="$(curl -k -I -sS "$CANONICAL_URL" 2>/dev/null | sed -n '1,12p')" && grep -q '^HTTP/2 200' <<<"$HTTP_HEADERS"; then
    break
  fi
  sleep 5
done

if ! grep -q '^HTTP/2 200' <<<"$HTTP_HEADERS"; then
  echo "[fail] Canonical dashboard URL did not return HTTP/2 200" >&2
  printf '%s\n' "$HTTP_HEADERS" >&2
  exit 1
fi
echo "[pass] Canonical dashboard URL returned HTTP/2 200"

RECENT_STATUS="$(remote "cd '$STACK_PATH' && docker compose ps")"
if ! grep -q 'healthy' <<<"$RECENT_STATUS"; then
  echo "[fail] Compose status does not show a healthy service" >&2
  exit 1
fi
echo "[pass] Compose status includes healthy services"
