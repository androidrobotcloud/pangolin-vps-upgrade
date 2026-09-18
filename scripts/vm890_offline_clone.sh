#!/usr/bin/env bash

set -euo pipefail

SOURCE_HOST="vm890"
SOURCE_USER="hustler2025"
SOURCE_STACK_PATH="/home/hustler2025/docker/pangolin-vps"

PROFILE="vm890-backup"
GUEST_NAME="pangolin-vm890-backup"
GUEST_OS="images:ubuntu/22.04"
GUEST_STACK_PATH="/home/hustler2025/docker/pangolin-vps"
GUEST_USER="hustler2025"

CPUS="4"
MEMORY_GIB="6"
DISK_GIB="40"

EXCLUDE_ACCESS_LOG=1
TAKE_SNAPSHOT=1
SNAPSHOT_NAME="initial-offline-clone"
START_STACK=0

usage() {
  cat <<'EOF'
Usage: scripts/vm890_offline_clone.sh [options]

Create or refresh the local offline Pangolin stack clone from vm890 into:
- a Colima profile
- a nested Incus guest
- Docker inside that guest

Safe-by-default behavior:
- clones the Pangolin stack only
- excludes backup tarballs and backup-only subtrees
- excludes .bak artifacts
- does not start the cloned stack unless asked

Options:
  --source-host HOST         Source SSH host (default: vm890)
  --source-user USER         Source SSH user (default: hustler2025)
  --source-path PATH         Source stack path (default: /home/hustler2025/docker/pangolin-vps)
  --profile NAME             Colima profile name (default: vm890-backup)
  --guest NAME               Incus guest name (default: pangolin-vm890-backup)
  --guest-user USER          Local user to create in guest (default: hustler2025)
  --cpus N                   Colima profile CPUs (default: 4)
  --memory-gib N             Colima profile memory in GiB (default: 6)
  --disk-gib N               Colima profile disk in GiB (default: 40)
  --start-stack              Start docker compose after staging
  --skip-snapshot            Do not create/refresh snapshot
  --keep-access-log          Include config/traefik/logs/access.log in clone
  -h, --help                 Show help

Examples:
  ./scripts/vm890_offline_clone.sh
  ./scripts/vm890_offline_clone.sh --profile vm890-backup-2 --guest pangolin-vm890-backup-2
  ./scripts/vm890_offline_clone.sh --start-stack
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-host)
      SOURCE_HOST="${2:?missing value for --source-host}"
      shift 2
      ;;
    --source-user)
      SOURCE_USER="${2:?missing value for --source-user}"
      shift 2
      ;;
    --source-path)
      SOURCE_STACK_PATH="${2:?missing value for --source-path}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:?missing value for --profile}"
      shift 2
      ;;
    --guest)
      GUEST_NAME="${2:?missing value for --guest}"
      shift 2
      ;;
    --guest-user)
      GUEST_USER="${2:?missing value for --guest-user}"
      shift 2
      ;;
    --cpus)
      CPUS="${2:?missing value for --cpus}"
      shift 2
      ;;
    --memory-gib)
      MEMORY_GIB="${2:?missing value for --memory-gib}"
      shift 2
      ;;
    --disk-gib)
      DISK_GIB="${2:?missing value for --disk-gib}"
      shift 2
      ;;
    --start-stack)
      START_STACK=1
      shift
      ;;
    --skip-snapshot)
      TAKE_SNAPSHOT=0
      shift
      ;;
    --keep-access-log)
      EXCLUDE_ACCESS_LOG=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

section() {
  printf '\n== %s ==\n' "$1"
}

note() {
  printf '[info] %s\n' "$1"
}

pass() {
  printf '[pass] %s\n' "$1"
}

fail() {
  printf '[fail] %s\n' "$1" >&2
  exit 1
}

ssh_src() {
  ssh "${SOURCE_USER}@${SOURCE_HOST}" "$@"
}

run_colima() {
  colima "$@"
}

run_vm() {
  run_colima ssh --profile "$PROFILE" -- sh -lc "$*"
}

run_guest() {
  local cmd="$1"
  run_vm "incus exec '$GUEST_NAME' -- sh -lc $(printf '%q' "$cmd")"
}

ensure_profile() {
  if ! run_colima status "$PROFILE" >/dev/null 2>&1; then
    note "Starting Colima profile '$PROFILE'"
    run_colima start "$PROFILE" \
      --runtime incus \
      --cpu "$CPUS" \
      --memory "$MEMORY_GIB" \
      --disk "$DISK_GIB" \
      --save-config
  else
    pass "Colima profile '$PROFILE' already running"
  fi
}

ensure_guest() {
  if ! run_vm "incus info '$GUEST_NAME' >/dev/null 2>&1"; then
    note "Launching Incus guest '$GUEST_NAME'"
    run_vm "incus launch '$GUEST_OS' '$GUEST_NAME' \
      -c security.nesting=true \
      -c security.syscalls.intercept.mknod=true \
      -c security.syscalls.intercept.setxattr=true"
  else
    pass "Incus guest '$GUEST_NAME' already exists"
  fi
}

install_guest_prereqs() {
  note "Installing Docker and helpers in '$GUEST_NAME'"
  run_guest "export DEBIAN_FRONTEND=noninteractive; apt-get update; apt-get install -y docker.io docker-compose-v2 curl ca-certificates"
  run_guest "id -u '$GUEST_USER' >/dev/null 2>&1 || useradd -m -s /bin/bash '$GUEST_USER'"
  run_guest "getent group docker >/dev/null 2>&1 || groupadd docker"
  run_guest "usermod -aG docker '$GUEST_USER'"
  run_guest "mkdir -p '$GUEST_STACK_PATH' && chown -R '$GUEST_USER:$GUEST_USER' \"/home/$GUEST_USER\""
  run_guest "systemctl enable --now docker"
  run_guest "docker --version && docker compose version >/dev/null"
}

detect_source_platform() {
  local arch
  arch="$(ssh_src "uname -m")"
  case "$arch" in
    x86_64|amd64)
      echo "linux/amd64"
      ;;
    aarch64|arm64)
      echo "linux/arm64"
      ;;
    *)
      fail "Unsupported source architecture: $arch"
      ;;
  esac
}

collect_source_image_refs() {
  ssh_src "cd '$SOURCE_STACK_PATH' && docker inspect pangolin gerbil traefik crowdsec --format '{{.Config.Image}}'" | sort -u
}

collect_source_image_digests() {
  local refs=()
  while IFS= read -r ref; do
    [[ -n "$ref" ]] && refs+=("$ref")
  done < <(collect_source_image_refs)
  if [[ ${#refs[@]} -eq 0 ]]; then
    fail "No source image refs found"
  fi
  ssh_src "docker image inspect ${refs[*]} --format '{{index .RepoDigests 0}}|{{join .RepoTags \",\"}}'"
}

create_stack_archive() {
  local out_file="$1"
  local access_log_exclude=""
  if [[ "$EXCLUDE_ACCESS_LOG" -eq 1 ]]; then
    access_log_exclude="--exclude=./config/traefik/logs/access.log"
  fi

  note "Exporting live Pangolin stack from ${SOURCE_USER}@${SOURCE_HOST}"
  ssh_src "docker run --rm -v '$SOURCE_STACK_PATH:/src:ro' alpine:3.20 sh -lc 'cd /src && tar \
    --exclude=./config/db/backups \
    --exclude=./config/traefik/backup \
    $access_log_exclude \
    --exclude=*.bak \
    --exclude=*.bak.* \
    -cf - docker-compose.yml config | gzip -1'" > "$out_file"
}

push_archive_to_guest() {
  local archive="$1"
  note "Pushing stack archive into '$GUEST_NAME'"
  run_colima ssh --profile "$PROFILE" -- sh -lc "cat > /tmp/$(basename "$archive")" < "$archive"
  run_vm "incus file push '/tmp/$(basename "$archive")' '$GUEST_NAME/home/$GUEST_USER/'"
  run_vm "rm -f '/tmp/$(basename "$archive")'"
}

extract_archive_in_guest() {
  local archive_name="$1"
  note "Extracting stack archive inside '$GUEST_NAME'"
  run_guest "mkdir -p '$GUEST_STACK_PATH' && tar -xzf '/home/$GUEST_USER/$archive_name' -C '$GUEST_STACK_PATH' && chown -R '$GUEST_USER:$GUEST_USER' '/home/$GUEST_USER/docker' && rm -f '/home/$GUEST_USER/$archive_name'"
  run_guest "cd '$GUEST_STACK_PATH' && docker compose config >/dev/null && find . -maxdepth 2 -type f | sort | sed -n '1,120p'"
}

cache_images_in_guest() {
  local platform="$1"
  local digest tag tags primary_tag

  section "Image Cache"
  while IFS='|' read -r digest tags; do
    [[ -n "$digest" ]] || continue
    IFS=',' read -r primary_tag _ <<< "$tags"
    note "Pulling $digest as $primary_tag"
    run_guest "docker pull --platform '$platform' '$digest' >/dev/null && id=\$(docker image inspect --format '{{.Id}}' '$digest') && docker tag \"\$id\" '$primary_tag'"
  done < <(collect_source_image_digests)

  pass "Exact source image set cached in '$GUEST_NAME'"
}

snapshot_guest() {
  if [[ "$TAKE_SNAPSHOT" -eq 1 ]]; then
    note "Refreshing snapshot '$SNAPSHOT_NAME'"
    run_vm "incus delete '$GUEST_NAME/$SNAPSHOT_NAME' >/dev/null 2>&1 || true"
    run_vm "incus snapshot create '$GUEST_NAME' '$SNAPSHOT_NAME'"
  fi
}

maybe_start_stack() {
  if [[ "$START_STACK" -eq 1 ]]; then
    note "Starting cloned stack in '$GUEST_NAME'"
    run_guest "cd '$GUEST_STACK_PATH' && docker compose up -d"
    run_guest "cd '$GUEST_STACK_PATH' && docker compose ps"
  else
    pass "Stack staged only; not started"
  fi
}

main() {
  need_cmd ssh
  need_cmd colima
  need_cmd gzip

  section "Source Check"
  ssh_src "echo CONNECTED && hostname && test -d '$SOURCE_STACK_PATH'"
  pass "Source host and stack path reachable"

  section "Target Setup"
  ensure_profile
  ensure_guest
  install_guest_prereqs

  section "Source Inventory"
  local platform
  platform="$(detect_source_platform)"
  note "Detected source platform: $platform"
  ssh_src "cd '$SOURCE_STACK_PATH' && docker compose ps && echo && docker compose images"

  local archive tmp_archive
  tmp_archive="$(mktemp "${TMPDIR:-/tmp}/vm890-offline-clone.XXXXXX")"
  archive="${tmp_archive}.tgz"
  mv "$tmp_archive" "$archive"
  trap 'rm -f "$archive"' EXIT

  section "Stack Export"
  create_stack_archive "$archive"
  ls -lh "$archive"

  section "Stack Import"
  push_archive_to_guest "$archive"
  extract_archive_in_guest "$(basename "$archive")"

  cache_images_in_guest "$platform"
  snapshot_guest
  maybe_start_stack

  section "Result"
  run_vm "incus info '$GUEST_NAME' | sed -n '1,120p'"
  pass "Offline clone workflow completed"
}

main "$@"
