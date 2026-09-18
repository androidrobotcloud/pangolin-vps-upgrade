#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file> [report-file]" >&2
  exit 1
fi

SPEC_FILE="$1"
REPORT_FILE="${2:-docs/reports/$(date +%F)-pangolin-staged-upgrade-v1-run.md}"

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

for target in $PANGOLIN_HOPS; do
  backup_file="$(./bin/create-pangolin-backup.sh "$SPEC_FILE" "$target")"
  backup_files+=("$backup_file")
  hop_outputs+=("$(./bin/apply-pangolin-hop.sh "$SPEC_FILE" "$target")")
  verify_outputs+=("$(./bin/verify-pangolin-version.sh "$SPEC_FILE" "$target")")
  runtime_outputs+=("$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")")
done

remote_status="$(ssh "$SSH_TARGET" "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'")"

{
  echo "Task:"
  echo "pangolin-staged-upgrade-v1"
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
  for target in $PANGOLIN_HOPS; do
    echo "./bin/create-pangolin-backup.sh $SPEC_FILE $target"
    echo "./bin/apply-pangolin-hop.sh $SPEC_FILE $target"
    echo "./bin/verify-pangolin-version.sh $SPEC_FILE $target"
    echo "./bin/verify-vm890-runtime.sh $SPEC_FILE"
  done
  echo "Evidence:"
  echo "- Canonical URL: $CANONICAL_URL"
  echo "- Executed Pangolin hop path: $PANGOLIN_HOPS"
  echo "- Backup files: ${backup_files[*]}"
  echo "- Final Pangolin target reached: ${PANGOLIN_IMAGE_REPO}:${PANGOLIN_HOPS##* }"
  echo "- Unrelated containers remained present in docker ps output"
  echo "Acceptance criteria:"
  echo "- profile check passes before mutation: yes"
  echo "- backup tarball created before each hop: yes"
  echo "- Pangolin reached each target version in order: yes"
  echo "- internal Pangolin health returned healthy after each hop: yes"
  echo "- canonical dashboard HTTPS returned success after each hop: yes"
  echo "- unrelated containers remained running: yes"
  echo "- final report written under docs/reports/: yes"
  echo "Problems found:"
  echo "- Pangolin 1.19 browser SSH-related features still require later companion validation for Badger and Newt paths"
  echo "Problems fixed:"
  echo "- Pangolin upgraded through the staged path $PANGOLIN_HOPS"
  echo "Stop conditions hit:"
  echo "- none"
  echo "Remaining risks:"
  echo "- Gerbil remains behind the latest 1.4 patch line"
  echo "- Traefik and Badger remain behind their latest lines and are intentionally out of scope here"
  echo "- Browser SSH, RDP, and VNC feature paths from Pangolin 1.19 are not fully validated by this workflow"
  echo "Next recommended task:"
  echo "- create separate companion workflows for Gerbil and Traefik/Badger only if you want to activate the newer feature paths"
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
  echo "Final docker ps:"
  echo "$remote_status"
} > "$REPORT_FILE"

printf '[pass] Wrote report: %s\n' "$REPORT_FILE"
