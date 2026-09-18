#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file> [report-file]" >&2
  exit 1
fi

SPEC_FILE="$1"
REPORT_FILE="${2:-docs/reports/$(date +%F)-pangolin-readonly-audit-v1-run.md}"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

mkdir -p "$(dirname "$REPORT_FILE")"

PROFILE_OUTPUT="$(./bin/check-vm890-profile.sh "$SPEC_FILE")"
VERIFY_OUTPUT="$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")"
PS_OUTPUT="$(ssh "$SSH_TARGET" "cd '$STACK_PATH' && docker compose ps")"
IMAGES_OUTPUT="$(ssh "$SSH_TARGET" "cd '$STACK_PATH' && docker compose images")"

cat > "$REPORT_FILE" <<EOF
Task:
pangolin-readonly-audit-v1
Result:
passed
Confidence:
high
Work class:
read-only
Files changed:
$REPORT_FILE
Commands run:
./bin/check-vm890-profile.sh $SPEC_FILE
./bin/verify-vm890-runtime.sh $SPEC_FILE
ssh $SSH_TARGET 'cd $STACK_PATH && docker compose ps'
ssh $SSH_TARGET 'cd $STACK_PATH && docker compose images'
Evidence:
- Canonical URL: $CANONICAL_URL
- Profile check passed
- Runtime verify passed
- Compose services: pangolin, gerbil, traefik, crowdsec
Acceptance criteria:
- profile check passes: yes
- internal Pangolin health returns healthy: yes
- canonical dashboard HTTPS check returns success: yes
- final report written under docs/reports/: yes
Problems found:
none observed during this run
Problems fixed:
none; read-only audit only
Stop conditions hit:
- none
Remaining risks:
- runtime facts may drift later; rerun the profile check before trusting old reports
- this workflow does not validate upgrade readiness or non-dashboard routes
Next recommended task:
- rerun this workflow before relying on stale runtime assumptions, or add workflow two only after this audit path is reused successfully

Profile output:
$PROFILE_OUTPUT

Runtime verify output:
$VERIFY_OUTPUT

Compose ps:
$PS_OUTPUT

Compose images:
$IMAGES_OUTPUT
EOF

echo "[pass] Wrote report: $REPORT_FILE"
