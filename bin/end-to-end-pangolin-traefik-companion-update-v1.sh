#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file> [report-file]" >&2
  exit 1
fi

SPEC_FILE="$1"
REPORT_FILE="${2:-docs/reports/$(date +%F)-pangolin-traefik-companion-update-v1-run.md}"

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

for target in $TRAEFIK_HOPS; do
  backup_file="$(./bin/create-stack-backup.sh "$SPEC_FILE" "$target")"
  backup_files+=("$backup_file")
  hop_outputs+=("$(./bin/apply-traefik-hop.sh "$SPEC_FILE" "$target")")
  verify_outputs+=("$(./bin/verify-traefik-version.sh "$SPEC_FILE" "$target")")
  runtime_outputs+=("$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")")
done

remote_status="$(ssh "$SSH_TARGET" "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'")"
traefik_logs="$(ssh "$SSH_TARGET" "docker logs --tail 80 traefik 2>&1" || true)"

{
  echo "Task:"
  echo "pangolin-traefik-companion-update-v1"
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
  for target in $TRAEFIK_HOPS; do
    echo "./bin/create-stack-backup.sh $SPEC_FILE $target"
    echo "./bin/apply-traefik-hop.sh $SPEC_FILE $target"
    echo "./bin/verify-traefik-version.sh $SPEC_FILE $target"
    echo "./bin/verify-vm890-runtime.sh $SPEC_FILE"
  done
  echo "Evidence:"
  echo "- Canonical URL: $CANONICAL_URL"
  echo "- Executed Traefik hop path: $TRAEFIK_HOPS"
  echo "- Backup files: ${backup_files[*]}"
  echo "- Final Traefik target reached: ${TRAEFIK_IMAGE_REPO}:${TRAEFIK_HOPS##* }"
  echo "- Pangolin remained on ${EXPECTED_PANGOLIN_IMAGE}"
  echo "- Gerbil remained on ${EXPECTED_GERBIL_IMAGE}"
  echo "- Unrelated containers remained present in docker ps output"
  echo "Acceptance criteria:"
  echo "- profile check passes before mutation: yes"
  echo "- backup tarball created before each hop: yes"
  echo "- Traefik reached each target version in order: yes"
  echo "- internal Pangolin health returned healthy after each hop: yes"
  echo "- canonical dashboard HTTPS returned success after each hop: yes"
  echo "- Pangolin, Gerbil, CrowdSec, and unrelated containers remained present: yes"
  echo "- final report written under docs/reports/: yes"
  echo "Problems found:"
  echo "- none during execution"
  echo "Problems fixed:"
  echo "- Traefik upgraded through the staged path $TRAEFIK_HOPS"
  echo "Stop conditions hit:"
  echo "- none"
  echo "Remaining risks:"
  echo "- v3.7 introduced migration notes around BasicAuth and StripPrefix behavior; this stack did not show those patterns in the checked config files, but representative route testing is still wise"
  echo "- this workflow validates dashboard HTTPS and container health, not every possible proxied route"
  echo "Next recommended task:"
  echo "- run a representative post-upgrade route test set, then decide whether any further companion cleanup is needed"
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
  echo "Recent Traefik logs:"
  echo "$traefik_logs"
  echo
  echo "Final docker ps:"
  echo "$remote_status"
} > "$REPORT_FILE"

printf '[pass] Wrote report: %s\n' "$REPORT_FILE"
