#!/usr/bin/env bash

set -euo pipefail

# Verifies that a target Pangolin/Gerbil/Traefik Docker image tag exists upstream
# WITHOUT pulling it onto the target host. Uses Docker Hub HTTP API.
# Exits non-zero if the tag cannot be confirmed.

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <full-image-ref>" >&2
  echo "Example: $0 docker.io/fosrl/pangolin:ee-1.22.2" >&2
  exit 1
fi

IMAGE_REF="$1"

# Parse repo:tag
if [[ "$IMAGE_REF" != *:* ]]; then
  echo "[fail] Image reference has no tag: $IMAGE_REF" >&2
  exit 1
fi
tag="${IMAGE_REF##*:}"
repo="${IMAGE_REF%:*}"

# docker.io/fosrl/pangolin -> fosrl/pangolin for Hub API
if [[ "$repo" == docker.io/* ]]; then
  repo="${repo#docker.io/}"
fi

echo "== target image verify =="
echo "Checking: $repo:$tag"

# Prefer the specific-tag endpoint (exact, paginated-list-independent).
http_code="$(curl -fsSL -o /dev/null -w "%{http_code}" "https://hub.docker.com/v2/repositories/${repo}/tags/${tag}" 2>/dev/null || echo "000")"

if [[ "$http_code" == "200" ]]; then
  echo "[pass] $repo:$tag exists on Docker Hub (HTTP 200)"
  exit 0
fi

if [[ "$http_code" == "000" ]]; then
  echo "[warn] Could not reach Docker Hub API for $repo" >&2
else
  echo "[info] Docker Hub returned HTTP $http_code for $repo:$tag" >&2
fi

# Fallback: registry manifest inspect (does not pull image layers).
echo "Falling back to registry manifest check..."
if docker manifest inspect "$IMAGE_REF" >/dev/null 2>&1; then
  echo "[pass] $IMAGE_REF confirmed via registry manifest inspect"
  exit 0
fi

echo "[fail] Cannot confirm $IMAGE_REF exists upstream" >&2
exit 1
