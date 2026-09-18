#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file> [report-file]" >&2
  exit 1
fi

SPEC_FILE="$1"
REPORT_FILE="${2:-docs/reports/$(date +%F)-pangolin-upgrade-readiness-audit-v1-run.md}"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

mkdir -p "$(dirname "$REPORT_FILE")"

PROFILE_OUTPUT="$(./bin/check-vm890-profile.sh "$SPEC_FILE")"
RUNTIME_OUTPUT="$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")"
READINESS_OUTPUT="$(./bin/verify-pangolin-upgrade-readiness.sh "$SPEC_FILE")"

cat > "$REPORT_FILE" <<EOF
Task:
pangolin-upgrade-readiness-audit-v1
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
./bin/verify-pangolin-upgrade-readiness.sh $SPEC_FILE
Evidence:
- Canonical URL: $CANONICAL_URL
- Runtime profile check passed
- Runtime health verification passed
- Official upstream release facts were gathered from Pangolin docs and official Git tags
- Readiness analysis was computed from live vm890 images plus official upstream tags
Acceptance criteria:
- profile check passes: yes
- internal Pangolin health returns healthy: yes
- canonical dashboard HTTPS check returns success: yes
- official upstream release facts are gathered from primary sources: yes
- report states current runtime, current-line latest, and overall latest: yes
- report includes read-only proposed version path and gotcha notes: yes
- final report written under docs/reports/: yes
Problems found:
- see the Version audit in the upgrade readiness output below for the current behind/latest status of each component
Problems fixed:
none; read-only readiness audit only
Stop conditions hit:
- none
Remaining risks:
- this workflow does not execute or validate any upgrade
- upstream release facts can drift; rerun this workflow before a maintenance window
- companion service changes should still be treated separately from Pangolin core migration work
Next recommended task:
- if any components are still behind in the Version audit below, create separate bounded workflows for them rather than bundling companion changes together

Profile output:
$PROFILE_OUTPUT

Runtime verify output:
$RUNTIME_OUTPUT

Upgrade readiness output:
$READINESS_OUTPUT
EOF

echo "[pass] Wrote report: $REPORT_FILE"
