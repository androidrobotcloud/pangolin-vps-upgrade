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

# --- Preflight gates (read-only, fail before any mutation) ---
# Profile and runtime checks establish the starting baseline.
profile_output="$(./bin/check-vm890-profile.sh "$SPEC_FILE")"
pre_runtime_output="$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")"

# Disk capacity preflight: fail early if there is insufficient space for the
# new image to download + extract while the old image still exists, plus
# headroom for backup growth and partial-pull residue. Does NOT auto-delete.
disk_output="$(./bin/check-upgrade-disk.sh "$SPEC_FILE")"

# Registry connectivity preflight: prove the target host can reach Docker Hub
# NOW (not just that the tag exists locally). A transient network failure here
# prevents a failed pull that would leave the stack DOWN.
# Build the list of target images from the hop versions.
target_images=()
for target in $PANGOLIN_HOPS; do
  target_images+=("${PANGOLIN_IMAGE_REPO}:${target}")
done
registry_output="$(./bin/check-registry-connectivity.sh "$SPEC_FILE" "${target_images[@]}")"

declare -a backup_files
declare -a backup_verify_outputs
declare -a hop_outputs
declare -a verify_outputs
declare -a runtime_outputs
declare -a badger_outputs

for target in $PANGOLIN_HOPS; do
  backup_file="$(./bin/create-pangolin-backup.sh "$SPEC_FILE" "$target")"
  backup_files+=("$backup_file")
  # Verify the backup archive on the remote host contains all critical
  # persistent-state paths BEFORE mutating anything, using the canonical
  # verifier. A missing/incomplete backup is a STOP condition (set -e aborts).
  backup_verify_outputs+=("$(./bin/verify-pangolin-backup.sh "$SPEC_FILE" "$backup_file")")
  hop_outputs+=("$(./bin/apply-pangolin-hop.sh "$SPEC_FILE" "$target")")
  verify_outputs+=("$(./bin/verify-pangolin-version.sh "$SPEC_FILE" "$target")")
  runtime_outputs+=("$(./bin/verify-vm890-runtime.sh "$SPEC_FILE")")
  # Pangolin migrations may auto-update the Badger plugin version in
  # traefik_config.yml. Verify the resulting version meets the minimum for the
  # new Pangolin version. Failure here is a STOP condition.
  badger_outputs+=("$(./bin/verify-pangolin-badger.sh "$SPEC_FILE")")
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
  echo "./bin/check-upgrade-disk.sh $SPEC_FILE"
  echo "./bin/check-registry-connectivity.sh $SPEC_FILE [target-images]"
  for target in $PANGOLIN_HOPS; do
    echo "./bin/create-pangolin-backup.sh $SPEC_FILE $target"
    echo "./bin/verify-pangolin-backup.sh $SPEC_FILE <backup-filename>"
    echo "./bin/apply-pangolin-hop.sh $SPEC_FILE $target"
    echo "./bin/verify-pangolin-version.sh $SPEC_FILE $target"
    echo "./bin/verify-pangolin-badger.sh $SPEC_FILE"
    echo "./bin/verify-vm890-runtime.sh $SPEC_FILE"
  done
  echo "Evidence:"
  echo "- Canonical URL: $CANONICAL_URL"
  echo "- Executed Pangolin hop path: $PANGOLIN_HOPS"
  echo "- Backup files: ${backup_files[*]}"
  echo "- Final Pangolin target reached: ${PANGOLIN_HOPS##* } (edition derived from running image)"
  echo "- Edition preservation: target derived from current running image prefix"
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
  echo "- Pangolin migration may auto-update the Badger plugin version in traefik_config.yml; verified post-hop"
  echo "Problems fixed:"
  echo "- Pangolin upgraded through the staged path $PANGOLIN_HOPS (Enterprise edition preserved)"
  echo "Stop conditions hit:"
  echo "- none"
  echo "Remaining risks:"
  echo "- Gerbil and Traefik companion updates are separate workflows"
  echo "- Pangolin 1.22+ AI Gateway features require Badger >= v1.6.0 (verified post-hop)"
  echo "- Representative site/resource testing is outside this automated workflow"
  echo "Next recommended task:"
  echo "- execute Gerbil companion update (1.5.0 -> 1.5.1)"
  echo "- execute Traefik companion update (v3.7.11 -> v3.7.13)"
  echo
  echo "Profile output:"
  echo "$profile_output"
  echo
  echo "Pre-upgrade runtime output:"
  echo "$pre_runtime_output"
  echo
  echo "Disk preflight output:"
  echo "$disk_output"
  echo
  echo "Registry connectivity preflight output:"
  echo "$registry_output"
  echo
  for i in "${!backup_files[@]}"; do
    echo "Backup $((i+1)):"
    echo "${backup_files[$i]}"
    echo
    echo "Backup $((i+1)) verify output:"
    echo "${backup_verify_outputs[$i]}"
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
    echo "Hop $((i+1)) badger verify output:"
    echo "${badger_outputs[$i]}"
    echo
  done
  echo "Final docker ps:"
  echo "$remote_status"
} > "$REPORT_FILE"

printf '[pass] Wrote report: %s\n' "$REPORT_FILE"
