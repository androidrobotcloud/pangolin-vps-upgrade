#!/usr/bin/env bash

set -euo pipefail

# Read-only registry-connectivity preflight for vm890 Pangolin upgrades.
#
# LESSON LEARNED (2026-09-18): verify-target-image.sh confirms that a target
# image tag EXISTS on Docker Hub by checking from the LOCAL workstation. But the
# actual pull happens from vm890. During the ee-1.22.2 -> ee-1.23.0 upgrade, the
# image tag existed (verified locally) but the target host could not reach
# Docker Hub's IPv6 registry endpoint, causing the pull to fail with:
#   dial tcp [2a06:98c1:3104::6812:2bb2]:443: connect: network is unreachable
#
# This check proves the TARGET HOST can reach the registry NOW, immediately
# before taking the stack down for mutation. It does NOT pull images.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <spec-file> [image-tag ...]" >&2
  echo "Example: $0 specs/pangolin-staged-upgrade-v1.vm890.conf docker.io/fosrl/pangolin:ee-1.23.0" >&2
  exit 1
fi

SPEC_FILE="$1"
shift

if [[ ! -f "$SPEC_FILE" ]]; then
  echo "[fail] Missing spec file: $SPEC_FILE" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$SPEC_FILE"

remote() {
  ssh "$SSH_TARGET" "$@"
}

echo "== registry connectivity preflight =="
echo "Host: $SSH_TARGET"

# --- Always verify Docker Hub API reachability from target host ---
echo
echo "Checking Docker Hub registry reachability from target host..."

# Check API v2 endpoint (lightweight, unauthenticated).
# NOTE: do NOT use -f here; we WANT to capture 401 responses (which -f treats
# as failures). Use -w to emit the HTTP code, then parse it.
hub_http="$(remote curl -sSL -o /dev/null -w '%{http_code}' --max-time 15 "https://registry-1.docker.io/v2/" 2>/dev/null | tr -d '[:space:]')"
# curl may output nothing on total failure; treat that as unreachable.
if [[ -z "$hub_http" ]]; then
  hub_http="000"
fi

if [[ "$hub_http" != "401" ]]; then
  # 401 is the expected response for unauthenticated /v2/ (it means "you're
  # reachable, but need a token for actual pulls"). Anything else (000 = unreachable,
  # timeout, etc.) is a connectivity problem.
  if [[ "$hub_http" == "000" ]]; then
    echo "[fail] Cannot reach Docker Hub registry (registry-1.docker.io) from $SSH_TARGET" >&2
    echo "       The registry is unreachable or timing out. Do not take the stack down for upgrade." >&2
  else
    echo "[warn] Docker Hub registry returned HTTP $hub_http (expected 401) from $SSH_TARGET" >&2
    echo "       Registry may be rate-limited or experiencing issues. Proceed with caution." >&2
    # Warn but don't fail on unexpected HTTP codes (could be transient/proxy)
  fi
  if [[ "$hub_http" == "000" ]]; then
    exit 1
  fi
else
  echo "[pass] Docker Hub registry reachable (HTTP 401 = expected unauthenticated)"
fi

# --- If specific image tags were provided, verify manifest reachability ---
if [[ $# -gt 0 ]]; then
  echo
  echo "Checking target image manifest reachability from target host..."
  for image_ref in "$@"; do
    # Parse repo:tag
    if [[ "$image_ref" != *:* ]]; then
      echo "[warn] Skipping malformed image ref (no tag): $image_ref" >&2
      continue
    fi
    tag="${image_ref##*:}"
    repo="${image_ref%:*}"
    # Strip docker.io/ prefix for Hub API path
    if [[ "$repo" == docker.io/* ]]; then
      repo="${repo#docker.io/}"
    fi

    # Use registry API to fetch the manifest. A 200 or 401 means the manifest
    # is reachable (401 = needs auth token, which is expected for unauthenticated
    # requests). A 404 means the tag doesn't exist. 000 means unreachable.
    # NOTE: do NOT use -f here; we WANT to capture 401 responses. Emit only the
    # HTTP code via -w, strip whitespace, and treat empty output as unreachable.
    # Pass the curl flags as separate arguments to avoid nested-quote parsing
    # issues inside the remote command substitution.
    manifest_hub_url="https://registry-1.docker.io/v2/${repo}/manifests/${tag}"

    manifest_http="$(remote curl -sSL -o /dev/null -w '%{http_code}' --max-time 20 "$manifest_hub_url" 2>/dev/null | tr -d '[:space:]')"
    if [[ -z "$manifest_http" ]]; then
      manifest_http="000"
    fi

    case "$manifest_http" in
      200|401)
        echo "[pass] $image_ref manifest reachable (HTTP $manifest_http)"
        ;;
      404)
        echo "[fail] $image_ref manifest NOT FOUND (HTTP 404) on Docker Hub" >&2
        exit 1
        ;;
      000)
        echo "[fail] $image_ref manifest UNREACHABLE from $SSH_TARGET (network error)" >&2
        echo "       Do not take the stack down. Registry connectivity is required for upgrade." >&2
        exit 1
        ;;
      *)
        echo "[warn] $image_ref manifest returned HTTP $manifest_http (expected 200 or 401)" >&2
        ;;
    esac
  done
fi

echo
echo "[pass] Registry connectivity preflight complete"
