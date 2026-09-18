#!/usr/bin/env bash

set -euo pipefail

# Post-restore / post-rollback service verification for vm890.
#
# LESSON LEARNED (2026-09-18): A successful filesystem backup restore is NOT
# sufficient proof of service recovery. After restoring from backup during the
# ee-1.22.2 -> ee-1.23.0 upgrade, the stack came up but external HTTPS returned
# 404 because Traefik's dynamic configuration was stale after the restore.
#
# This helper verifies all service layers and, if HTTPS routing is broken,
# provides a decision path to recovery (restart Traefik to re-fetch config
# from Pangolin's HTTP provider).
#
# This is a READ-ONLY diagnostic/verification tool. It does NOT restart services
# automatically — the operator must act on its findings (or pass --fix).

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <spec-file> [--fix]" >&2
  exit 1
fi

SPEC_FILE="$1"
FIX_MODE="${2:-}"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

# Run a command on the remote host, capturing stdout. Fails the script on
# SSH failure but NOT on remote command failure (so we can inspect error output).
remote_exec() {
  ssh "$SSH_TARGET" "$@"
}

echo "== post-restore service verification =="
echo "Host: $SSH_TARGET"
echo

fail=0

# --- Layer 1: Pangolin container running ---
echo "--- Layer 1: Pangolin container ---"
if pangolin_status="$(remote_exec docker inspect pangolin --format '{{.State.Status}}' 2>/dev/null)"; then
  if [[ "$pangolin_status" == "running" ]]; then
    echo "[pass] Pangolin container: running"
  else
    echo "[fail] Pangolin container status: $pangolin_status (expected: running)" >&2
    fail=1
  fi
else
  echo "[fail] Pangolin container: missing or inspect failed" >&2
  fail=1
fi

# --- Layer 2: Pangolin internal health ---
echo "--- Layer 2: Pangolin internal health ---"
health="$(remote_exec docker exec pangolin curl -fsS http://localhost:3001/api/v1/ 2>/dev/null || echo 'UNREACHABLE')"
if [[ "$health" == *"Healthy"* ]]; then
  echo "[pass] Pangolin health: Healthy"
else
  echo "[fail] Pangolin health: $health" >&2
  fail=1
fi

# --- Layer 3: Internal dashboard ---
echo "--- Layer 3: Internal dashboard ---"
internal_http="$(remote_exec docker exec pangolin curl -fsS -o /dev/null -w '%{http_code}' http://localhost:3002 2>/dev/null || echo '000')"
if [[ "$internal_http" == "200" ]]; then
  echo "[pass] Internal dashboard (localhost:3002): HTTP 200"
else
  echo "[fail] Internal dashboard: HTTP $internal_http" >&2
  fail=1
fi

# --- Layer 4: Traefik container running ---
echo "--- Layer 4: Traefik container ---"
traefik_status="$(remote_exec docker inspect traefik --format '{{.State.Status}}' 2>/dev/null || echo 'missing')"
if [[ "$traefik_status" == "running" ]]; then
  echo "[pass] Traefik container: running"
else
  echo "[fail] Traefik container status: $traefik_status (expected: running)" >&2
  fail=1
fi

# --- Layer 5: Traefik HTTPS routers enabled ---
echo "--- Layer 5: Traefik HTTPS routers ---"
# Fetch router list from Traefik API and check for disabled websecure routers.
routers_output="$(remote_exec docker exec traefik wget -qO- http://localhost:8080/api/http/routers 2>/dev/null || echo '')"
if [[ -z "$routers_output" ]]; then
  echo "[fail] Traefik API unreachable" >&2
  fail=1
else
  # Use python to parse router statuses (avoids fragile shell parsing).
  router_check="$(echo "$routers_output" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
except Exception:
    print('PARSE_ERROR')
    sys.exit(0)
websecure = [r for r in data if 'websecure' in r.get('entryPoints', [])]
disabled = [r['name'] for r in websecure if r.get('status') != 'enabled']
if disabled:
    print('DISABLED:' + ','.join(disabled))
else:
    print('ALL_ENABLED')
" 2>/dev/null || echo 'PARSE_ERROR')"

  case "$router_check" in
    ALL_ENABLED)
      echo "[pass] Traefik HTTPS routers: all enabled"
      ;;
    PARSE_ERROR)
      echo "[fail] Could not parse Traefik router API response" >&2
      fail=1
      ;;
    DISABLED:*)
      disabled_names="${router_check#DISABLED:}"
      echo "[fail] Traefik HTTPS routers DISABLED: $disabled_names" >&2
      echo >&2
      echo "  This usually means Traefik's dynamic configuration is stale." >&2
      echo "  If verification passes for layers 1-4, restart Traefik to re-fetch" >&2
      echo "  config from Pangolin HTTP provider:" >&2
      echo "    ssh $SSH_TARGET 'cd $STACK_PATH && docker compose restart traefik'" >&2
      echo "  Or run: $0 $SPEC_FILE --fix" >&2
      fail=1
      ;;
  esac
fi

# --- Layer 6: Direct backend reachability ---
echo "--- Layer 6: Direct backend reachability ---"
backend_http="$(remote_exec docker exec traefik wget -qO- --timeout=5 -o /dev/null -w '%{http_code}' http://pangolin:3002 2>/dev/null || echo '000')"
if [[ "$backend_http" == "200" ]]; then
  echo "[pass] Backend reachable from Traefik (pangolin:3002): HTTP 200"
else
  echo "[warn] Backend reachability: HTTP $backend_http" >&2
fi

# --- Layer 7: External HTTPS ---
echo "--- Layer 7: Canonical external HTTPS ---"
external_http="$(curl -k -I -sS --max-time 15 "$CANONICAL_URL" 2>/dev/null | head -1 | awk '{print $2}')"
if [[ "$external_http" == "200" ]]; then
  echo "[pass] External HTTPS ($CANONICAL_URL): HTTP 200"
else
  echo "[fail] External HTTPS ($CANONICAL_URL): ${external_http:-UNREACHABLE}" >&2
  fail=1
fi

echo

# --- Optional fix: restart Traefik if routers are disabled ---
if [[ "$FIX_MODE" == "--fix" && "$router_check" == DISABLED:* ]]; then
  echo "=== FIX: Restarting Traefik to re-fetch dynamic config ==="
  remote_exec cd "$STACK_PATH" && docker compose restart traefik
  echo "Waiting 15s for Traefik to re-fetch config..."
  sleep 15
  echo
  echo "=== Re-verifying after fix ==="

  # Re-fetch router status
  routers_after="$(remote_exec docker exec traefik wget -qO- http://localhost:8080/api/http/routers 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
websecure = [r for r in data if 'websecure' in r.get('entryPoints', [])]
disabled = [r['name'] for r in websecure if r.get('status') != 'enabled']
print('ALL_ENABLED' if not disabled else 'DISABLED:' + ','.join(disabled))
" 2>/dev/null || echo 'PARSE_ERROR')"

  case "$routers_after" in
    ALL_ENABLED)
      echo "[pass] After restart: HTTPS routers enabled"
      external_after="$(curl -k -I -sS --max-time 15 "$CANONICAL_URL" 2>/dev/null | head -1 | awk '{print $2}')"
      if [[ "$external_after" == "200" ]]; then
        echo "[pass] After restart: External HTTPS HTTP 200"
        fail=0
      else
        echo "[warn] After restart: External HTTPS still ${external_after:-UNREACHABLE}" >&2
      fi
      ;;
    *)
      echo "[fail] After restart: routers still disabled ($routers_after)" >&2
      fail=1
      ;;
  esac
  echo
elif [[ "$FIX_MODE" == "--fix" ]]; then
  echo "(--fix requested but routers are already enabled; no restart needed)"
  echo
fi

if [[ $fail -eq 0 ]]; then
  echo "[pass] All service layers verified. Recovery complete."
  exit 0
else
  echo "[fail] Service verification FAILED. See above for details."
  exit 1
fi
