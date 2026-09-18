#!/usr/bin/env bash

set -euo pipefail

# Read-only disk-capacity preflight for vm890 Pangolin upgrades.
#
# LESSON LEARNED (2026-09-18): During the ee-1.22.2 -> ee-1.23.0 upgrade, the
# host reached 99% disk usage (~253 MB free on 20 GB) after a failed image pull.
# The new Pangolin image needs space to download AND extract while the old image
# still exists, plus headroom for backup growth and partial-pull residue.
#
# This check runs BEFORE the first mutation. It does NOT delete anything.
# If capacity is insufficient, it reports reclaimable Docker images as
# candidates for OPERATOR review and stops.

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

remote() {
  ssh "$SSH_TARGET" "$@"
}

echo "== upgrade disk preflight =="

# --- Filesystem capacity ---
# Require BOTH an absolute free-space floor AND a usage ceiling.
# Percentage alone is insufficient: 99% of 20 GB (253 MB free) is very
# different from 99% of 1 TB (10 GB free).
df_output="$(remote "df -BG '$STACK_PATH' 2>/dev/null | tail -1")"

# Parse df output: filesystem, size, used, avail, use%, mount
read -r _fs _size_g _used_g avail_g use_pct _mount <<<"$df_output"
avail_num="${avail_g%G}"
use_num="${use_pct%\%}"

echo "Filesystem: $df_output"
echo "Available:  ${avail_g} (${avail_num} GB)"
echo "Usage:      ${use_pct} (${use_num}%)"

# Thresholds (conservative, evidence-based from the 2026-09-18 run)
min_free_g=2     # absolute floor: covers extraction + backup growth + residue
max_use_pct=90   # percentage ceiling: catches near-full large filesystems

fail=0

if [[ "${avail_num%.*}" -lt "$min_free_g" ]]; then
  echo "[fail] Available space ${avail_g} is below minimum ${min_free_g} GB" >&2
  fail=1
fi

if [[ "$use_num" -gt "$max_use_pct" ]]; then
  echo "[fail] Disk usage ${use_pct} is above maximum ${max_use_pct}%" >&2
  fail=1
fi

if [[ $fail -eq 1 ]]; then
  echo
  echo "Disk capacity is unsafe for upgrade. Reclaim space before proceeding."
  echo
  echo "Reclaimable Docker images (inactive, safe to remove with operator review):"
  remote "docker images --format '  {{.Repository}}:{{.Tag}}  {{.Size}}  # created {{.Since}}' | grep -E '(pangolin|<none>)'" 2>/dev/null || true
  echo
  echo "Dangling image layers:"
  remote "docker system df 2>/dev/null | tail -1" || true
  echo
  echo "NOTE: This helper does NOT delete anything. Review candidates above"
  echo "and remove manually, e.g.:"
  echo "  ssh $SSH_TARGET docker image rm <repository>:<tag>"
  exit 1
fi

echo "[pass] Disk capacity OK: ${avail_g} free, ${use_pct} used"
