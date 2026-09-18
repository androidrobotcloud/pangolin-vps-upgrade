#!/usr/bin/env bash

set -euo pipefail

# Verifies the Badger plugin version in the live Traefik config meets the minimum
# required for the currently-running Pangolin version.
#
# Pangolin's migration auto-updates Badger in traefik_config.yml when the config
# matches the default installer format (proven historically on this environment:
# 1.19 migration bumped Badger to v1.4.1 automatically). This helper confirms the
# auto-update landed; if it did not, the workflow must STOP for manual resolution.

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <spec-file> [minimum-badger-version]" >&2
  exit 1
fi

SPEC_FILE="$1"
MIN_BADGER_VERSION="${2:-}"

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

remote() {
  ssh "$SSH_TARGET" "$@"
}

echo "== pangolin badger verify =="

# Read the Badger plugin version from live Traefik config.
badger_version="$(remote "cd '$STACK_PATH' && awk '/badger:/{f=1} f&&/version:/{gsub(/\"/, \"\", \$2); print \$2; exit}' config/traefik/traefik_config.yml")"

if [[ -z "$badger_version" ]]; then
  echo "[fail] Could not read Badger version from traefik_config.yml" >&2
  exit 1
fi

# Read the current Pangolin version.
pangolin_image="$(remote "docker inspect pangolin --format '{{.Config.Image}}'")"
pangolin_version="${pangolin_image##*:}"
# Strip edition prefix (ee-) to get numeric version
pangolin_numeric="${pangolin_version#ee-}"

echo "Pangolin: $pangolin_version"
echo "Badger:    $badger_version"

# Derive the minimum Badger version from Pangolin version if not explicitly given.
# Pangolin 1.22.0+ (AI Gateway) requires Badger >= v1.6.0.
if [[ -z "$MIN_BADGER_VERSION" ]]; then
  pangolin_major="$(echo "$pangolin_numeric" | cut -d. -f1)"
  pangolin_minor="$(echo "$pangolin_numeric" | cut -d. -f2)"
  if [[ "$pangolin_major" -ge 1 && "$pangolin_minor" -ge 22 ]]; then
    MIN_BADGER_VERSION="v1.6.0"
  else
    MIN_BADGER_VERSION="v1.4.0"
  fi
fi

echo "Minimum Badger required: $MIN_BADGER_VERSION"

# Compare versions using Python for reliable semver comparison.
result="$(python3 - "$badger_version" "$MIN_BADGER_VERSION" <<'PY'
import sys
import re

def parse(v: str):
    nums = re.findall(r"\d+", v)
    while len(nums) < 3:
        nums.append(0)
    return tuple(int(n) for n in nums[:3])

have = parse(sys.argv[1])
need = parse(sys.argv[2])
if have >= need:
    print("ok")
else:
    print("below")
PY
)"

if [[ "$result" == "below" ]]; then
  echo "[fail] Badger $badger_version is below minimum $MIN_BADGER_VERSION for Pangolin $pangolin_version" >&2
  echo "Pangolin's migration did not update Badger automatically." >&2
  echo "Manual update of config/traefik/traefik_config.yml is required before proceeding." >&2
  exit 1
fi

echo "[pass] Badger $badger_version meets minimum $MIN_BADGER_VERSION for Pangolin $pangolin_version"
