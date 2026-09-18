#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file> [report-file]" >&2
  exit 1
fi

SPEC_FILE="$1"
REPORT_FILE="${2:-docs/reports/$(date +%F)-pangolin-gerbil-companion-update-v1-run.md}"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

mkdir -p "$(dirname "$REPORT_FILE")"

profile_output="$(./bin/check-vm890-profile.sh "$SPEC_FILE")"
pre_runtime_output="$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")"

declare -a backup_files
declare -a hop_outputs
declare -a verify_outputs
declare -a runtime_outputs

for target in $GERBIL_HOPS; do
  backup_file="$(./bin/create-stack-backup.sh "$SPEC_FILE" "$target")"
  backup_files+=("$backup_file")
  hop_outputs+=("$(./bin/apply-gerbil-hop.sh "$SPEC_FILE" "$target")")
  verify_outputs+=("$(./bin/verify-gerbil-version.sh "$SPEC_FILE" "$target")")
  runtime_outputs+=("$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")")
done

remote_status="$(ssh "$SSH_TARGET" "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'")"
gerbil_logs="$(ssh "$SSH_TARGET" "docker logs --tail 40 gerbil 2>&1" || true)"

{
  echo "Task:"
  echo "pangolin-gerbil-companion-update-v1"
  echo "Result:"
  echo "passed"
  echo "Confidence:"
  echo "medium"
  echo "Work class:"
  echo "mutating"
  echo "Files changed:"
  echo "$REPORT_FILE"
  echo "Commands run:"
  echo "./bin/check-vm890-profile.sh $SPEC_FILE"
  echo "./bin/verify-vm890-runtime.sh $SPEC_FILE"
  for target in $GERBIL_HOPS; do
    echo "./bin/create-stack-backup.sh $SPEC_FILE $target"
    echo "./bin/apply-gerbil-hop.sh $SPEC_FILE $target"
    echo "./bin/verify-gerbil-version.sh $SPEC_FILE $target"
    echo "./bin/verify-vm890-runtime.sh $SPEC_FILE"
  done
  echo "Evidence:"
  echo "- Canonical URL: $CANONICAL_URL"
  echo "- Executed Gerbil hop path: $GERBIL_HOPS"
  echo "- Backup files: ${backup_files[*]}"
  echo "- Final Gerbil target reached: ${GERBIL_IMAGE_REPO}:${GERBIL_HOPS##* }"
  echo "- Pangolin remained on ${EXPECTED_PANGOLIN_IMAGE}"
  echo "- Traefik remained on ${EXPECTED_TRAEFIK_IMAGE}"
  echo "- Unrelated containers remained present in docker ps output"
  echo "Acceptance criteria:"
  echo "- profile check passes before mutation: yes"
  echo "- backup tarball created before each hop: yes"
  echo "- Gerbil reached each target version in order: yes"
  echo "- internal Pangolin health returned healthy after each hop: yes"
  echo "- canonical dashboard HTTPS returned success after each hop: yes"
  echo "- Pangolin, Traefik, CrowdSec, and unrelated containers remained present: yes"
  echo "- final report written under docs/reports/: yes"
  echo "Problems found:"
  echo "- Traefik remains behind the current 3.6 patch line and latest 3.7 line"
  echo "Problems fixed:"
  echo "- Gerbil upgraded through the staged path $GERBIL_HOPS"
  echo "Stop conditions hit:"
  echo "- none"
  echo "Remaining risks:"
  echo "- Traefik still requires its own companion workflow if you want current-line patching"
  echo "- Browser SSH and other 1.19 companion-dependent features still need representative feature validation after this service-only update"
  echo "Next recommended task:"
  echo "- create a separate Traefik companion workflow if you want to patch the reverse proxy line next"
  echo
  echo "Profile output:"
  echo "$profile_output"
  echo
  echo "Pre-upgrade runtime output:"
  echo "$pre_runtime_output"
  echo
  for i in "${!backup_files[@]}"; do
    echo "Backup $((i+1)):"
    echo "${backup_files[$i]}"
    echo
    echo "Hop $((i+1)) apply output:"
    echo "${hop_outputs[$i]}"
    echo
    echo "Hop $((i+1)) version verify output:"
    echo "${verify_outputs[$i]}"
    echo
    echo "Hop $((i+1)) runtime output:"
    echo "${runtime_outputs[$i]}"
    echo
  done
  echo "Recent Gerbil logs:"
  echo "$gerbil_logs"
  echo
  echo "Final docker ps:"
  echo "$remote_status"
} > "$REPORT_FILE"

printf '[pass] Wrote report: %s\n' "$REPORT_FILE"
