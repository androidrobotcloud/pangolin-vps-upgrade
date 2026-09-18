#!/usr/bin/env bash

set -euo pipefail

PROFILE="incus-lan"
INTERFACE="en0"
TEST_INSTANCE="lan-test"
BRIDGE_NAME="br0"
LAUNCH_TEST=0
USE_BRIDGE=0

usage() {
  cat <<'EOF'
Usage: colima_incus_bridged_sanity.sh [options]

Safe-by-default sanity checks for:
- a bridged Colima VM on macOS
- Incus networking inside that VM
- optional disposable nested Incus container tests

Default behavior is read-only.

Options:
  --profile NAME        Colima profile name (default: incus-lan)
  --interface NAME      macOS interface expected for bridged mode (default: en0)
  --bridge NAME         Linux bridge to test inside the Colima VM (default: br0)
  --instance NAME       Disposable Incus test instance name (default: lan-test)
  --launch-test         Launch a disposable Incus test instance
  --use-bridge          When used with --launch-test, attach the test instance to br0
  -h, --help            Show this help

Examples:
  ./scripts/colima_incus_bridged_sanity.sh
  ./scripts/colima_incus_bridged_sanity.sh --launch-test
  ./scripts/colima_incus_bridged_sanity.sh --launch-test --use-bridge --bridge br0
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:?missing value for --profile}"
      shift 2
      ;;
    --interface)
      INTERFACE="${2:?missing value for --interface}"
      shift 2
      ;;
    --bridge)
      BRIDGE_NAME="${2:?missing value for --bridge}"
      shift 2
      ;;
    --instance)
      TEST_INSTANCE="${2:?missing value for --instance}"
      shift 2
      ;;
    --launch-test)
      LAUNCH_TEST=1
      shift
      ;;
    --use-bridge)
      USE_BRIDGE=1
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

run_colima() {
  colima "$@"
}

run_vm() {
  run_colima ssh --profile "$PROFILE" -- sh -lc "$*"
}

show_net() {
  if run_vm "command -v ip >/dev/null 2>&1"; then
    run_vm "ip -br addr"
  else
    run_vm "ifconfig 2>/dev/null || true"
  fi
}

show_link() {
  local link_name="$1"
  if run_vm "command -v ip >/dev/null 2>&1"; then
    run_vm "ip -br link show '$link_name'"
  else
    run_vm "ifconfig '$link_name'"
  fi
}

section() {
  printf '\n== %s ==\n' "$1"
}

note() {
  printf '[info] %s\n' "$1"
}

warn() {
  printf '[warn] %s\n' "$1" >&2
}

pass() {
  printf '[pass] %s\n' "$1"
}

fail() {
  printf '[fail] %s\n' "$1" >&2
}

cleanup_test_instance() {
  if [[ "$LAUNCH_TEST" -eq 1 ]]; then
    run_vm "incus delete -f '$TEST_INSTANCE' >/dev/null 2>&1 || true"
  fi
}

trap cleanup_test_instance EXIT

need_cmd colima

section "Host Checks"
pass "Found colima"

if ifconfig "$INTERFACE" >/dev/null 2>&1; then
  pass "Host interface '$INTERFACE' exists"
else
  fail "Host interface '$INTERFACE' does not exist"
  exit 1
fi

section "Colima Profile"
if ! run_colima status "$PROFILE" >/dev/null 2>&1; then
  fail "Colima profile '$PROFILE' is not running"
  cat <<EOF
Start it with something like:
  colima start $PROFILE --runtime incus --network-address --network-mode bridged --network-interface $INTERFACE --cpu 2 --memory 4 --disk 60 --save-config
EOF
  exit 1
fi
pass "Colima profile '$PROFILE' is running"

note "Current Colima status:"
run_colima status "$PROFILE"

section "VM Network"
note "VM addresses:"
show_net

section "Incus Basics"
note "Incus version:"
run_vm "incus version"

note "Incus networks:"
run_vm "incus network list"

note "Default profile:"
run_vm "incus profile show default"

section "Bridge Check"
if show_link "$BRIDGE_NAME" >/dev/null 2>&1; then
  pass "Bridge '$BRIDGE_NAME' exists inside the Colima VM"
  show_link "$BRIDGE_NAME"
else
  warn "Bridge '$BRIDGE_NAME' does not exist inside the Colima VM"
  cat <<EOF
This means nested Incus instances cannot be attached with:
  incus config device add <instance> eth0 nic nictype=bridged parent=$BRIDGE_NAME

You can still use:
- the Colima VM's own bridged LAN IP
- Incus managed networks inside the VM
EOF
fi

section "Nested Docker Readiness"
note "Checking whether Docker-in-Incus guest containers are likely to work:"
run_vm "incus profile show default | sed -n '/devices:/,\$p'"
cat <<EOF
[info] If Docker-in-Incus is part of your test plan, also verify instance-level settings like:
  security.nesting=true
  security.syscalls.intercept.mknod=true
  security.syscalls.intercept.setxattr=true
EOF

if [[ "$LAUNCH_TEST" -eq 0 ]]; then
  section "Result"
  pass "Read-only sanity check completed"
  cat <<EOF

To run a disposable nested Incus test:
  ./scripts/colima_incus_bridged_sanity.sh --launch-test

To test a bridge-backed nested Incus NIC (only if $BRIDGE_NAME exists):
  ./scripts/colima_incus_bridged_sanity.sh --launch-test --use-bridge --bridge $BRIDGE_NAME
EOF
  exit 0
fi

section "Disposable Nested Incus Test"
run_vm "incus delete -f '$TEST_INSTANCE' >/dev/null 2>&1 || true"

if [[ "$USE_BRIDGE" -eq 1 ]]; then
  if ! show_link "$BRIDGE_NAME" >/dev/null 2>&1; then
    fail "Requested bridge test, but '$BRIDGE_NAME' does not exist"
    exit 1
  fi
  note "Launching nested test instance attached to '$BRIDGE_NAME'"
  run_vm "incus launch images:debian/12 '$TEST_INSTANCE' -d eth0,nictype=bridged,parent=$BRIDGE_NAME"
else
  note "Launching nested test instance with default profile networking"
  run_vm "incus launch images:debian/12 '$TEST_INSTANCE'"
fi

note "Waiting for the guest to settle..."
run_vm "sleep 5"

note "Instance summary:"
run_vm "incus list '$TEST_INSTANCE'"

note "Guest addresses:"
run_vm "incus exec '$TEST_INSTANCE' -- ip -br addr"

if run_vm "incus exec '$TEST_INSTANCE' -- bash -lc 'command -v dhclient >/dev/null 2>&1 || command -v systemctl >/dev/null 2>&1'" >/dev/null 2>&1; then
  pass "Nested test guest booted and accepted exec commands"
else
  warn "Nested guest is up, but exec-based checks were limited"
fi

section "Result"
pass "Disposable nested Incus test completed"
cat <<EOF
The test instance '$TEST_INSTANCE' will be deleted automatically when this script exits.
If you want to inspect it manually, comment out the trap in the script first.
EOF
