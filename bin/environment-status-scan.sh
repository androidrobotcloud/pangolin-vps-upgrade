#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then echo 'Usage: environment-status-scan.sh <environment-id>' >&2; exit 2; fi
ENV_ID="$1"
SPEC="specs/environments/$ENV_ID.conf"
[[ -f docs/ENVIRONMENTS.md ]] || { echo '[fail] ENVIRONMENTS missing' >&2; exit 1; }
[[ -f "$SPEC" ]] || { echo "[fail] Unknown environment: $ENV_ID" >&2; exit 1; }
source "$SPEC"
[[ "$ENV_NAME" == "$ENV_ID" ]] || { echo '[fail] Spec identity mismatch' >&2; exit 1; }
REPORT="docs/reports/$(date +%F)-environment-status-$ENV_ID.md"
mkdir -p docs/reports
case "$ADAPTER" in
  ssh_pangolin)
    ACTUAL_HOSTNAME="$(ssh "$SSH_TARGET" hostname)"
    if [[ -n "${EXPECTED_HOSTNAME:-}" && "$ACTUAL_HOSTNAME" != "$EXPECTED_HOSTNAME" ]]; then echo '[fail] Hostname mismatch' >&2; exit 1; fi
    ssh "$SSH_TARGET" "test -d '$STACK_PATH'" || { echo '[fail] Stack path missing' >&2; exit 1; }
    SERVICES="$(ssh "$SSH_TARGET" "cd '$STACK_PATH' && docker compose ps")"
    IMAGES="$(ssh "$SSH_TARGET" "cd '$STACK_PATH' && docker compose images")"
    HEALTH="$(ssh "$SSH_TARGET" "docker exec pangolin curl -fsS http://localhost:3001/api/v1/" 2>&1 || true)"
    URL_STATUS="$(curl -k -sS -o /dev/null -w '%{http_code}' "$CANONICAL_URL" || true)"
    PREVIOUS="$(ls -1t docs/reports/*-environment-status-$ENV_ID.md 2>/dev/null | head -1 || true)"
    printf 'Task: environment-status-scan-v1\nEnvironment ID: %s\nScan timestamp: %s\nResult: evidence-collected\nPrevious baseline: %s\nObserved evidence:\n- hostname: %s\n- stack: %s\n- Pangolin health: %s\n- canonical HTTP: %s\nCompose images:\n%s\nCompose status:\n%s\nDifferences: compare with %s and previous scan\nENVIRONMENTS.md comparison: review standard fields; update only material changes\nProblems fixed: none; infrastructure scan is read-only\n' "$ENV_ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${PREVIOUS:-none}" "$ACTUAL_HOSTNAME" "$STACK_PATH" "$HEALTH" "$URL_STATUS" "$IMAGES" "$SERVICES" "$RUNTIME_DOC" > "$REPORT"
    ;;
  manual)
    echo "[stop] $ENV_ID has no proven automated adapter yet. Read $RUNTIME_DOC and add/verify a read-only collector first." >&2
    exit 3
    ;;
  *) echo "[fail] Unknown adapter: $ADAPTER" >&2; exit 1 ;;
esac
echo "[pass] Wrote evidence report: $REPORT"
echo '[next] Compare with ENVIRONMENTS.md, runtime profile and prior scan; update permitted docs only.'
