#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: diagnose-crowdsec-403.sh <ssh-target> <stack-path> <source-ip>

Example:
  ./bin/diagnose-crowdsec-403.sh revelectronics@tony_vps /home/revelectronics/docker/pangolin 109.157.221.152

This helper is read-only. It is meant to confirm whether a visible 403 is
coming from the CrowdSec middleware in front of Pangolin/Traefik.
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[fail] Missing required command: $1" >&2
    exit 1
  }
}

for cmd in ssh python3 mktemp; do
  need_cmd "$cmd"
done

if [[ $# -ne 3 ]]; then
  usage >&2
  exit 1
fi

SSH_TARGET="$1"
STACK_PATH="$2"
SOURCE_IP="$3"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ssh "$SSH_TARGET" "docker exec crowdsec sh -lc 'cscli decisions list -i \"$SOURCE_IP\" -o json'" \
  > "$TMPDIR/decisions.json"

ssh "$SSH_TARGET" "docker exec crowdsec sh -lc 'cscli alerts list -o json'" \
  > "$TMPDIR/alerts.json"

ssh "$SSH_TARGET" "python3 - '$STACK_PATH' '$SOURCE_IP' <<'PY'
import json
import sys
from pathlib import Path

stack_path = Path(sys.argv[1])
source_ip = sys.argv[2]
log_path = stack_path / 'config' / 'traefik' / 'logs' / 'access.log'

matches = []
if log_path.exists():
    with log_path.open('r', encoding='utf-8', errors='replace') as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except Exception:
                continue
            if obj.get('ClientHost') != source_ip:
                continue
            matches.append({
                'time': obj.get('time') or obj.get('StartUTC'),
                'status': obj.get('DownstreamStatus'),
                'path': obj.get('RequestPath'),
                'service': obj.get('ServiceName') or '',
                'user_agent': obj.get('request_User-Agent') or '',
            })

recent = matches[-60:]
status_403 = [m for m in recent if m.get('status') == 403]
middleware_403 = [m for m in status_403 if not m.get('service')]

print(json.dumps({
    'total_recent_matches': len(recent),
    'recent_403_count': len(status_403),
    'recent_middleware_403_count': len(middleware_403),
    'recent': recent,
}, indent=2))
PY" > "$TMPDIR/access.json"

ssh "$SSH_TARGET" "docker exec crowdsec cscli allowlists list 2>/dev/null || true" \
  > "$TMPDIR/allowlists.txt"

python3 - "$SOURCE_IP" "$TMPDIR/decisions.json" "$TMPDIR/alerts.json" "$TMPDIR/access.json" "$TMPDIR/allowlists.txt" <<'PY'
import json
import sys
from pathlib import Path

source_ip, decisions_path, alerts_path, access_path, allowlists_path = sys.argv[1:6]

decisions = json.loads(Path(decisions_path).read_text() or "[]")
alerts = json.loads(Path(alerts_path).read_text() or "[]")
access = json.loads(Path(access_path).read_text() or "{}")
allowlists = Path(allowlists_path).read_text().strip()

if decisions is None:
    decisions = []
if alerts is None:
    alerts = []
if access is None:
    access = {}
if not isinstance(decisions, list):
    decisions = []
if not isinstance(alerts, list):
    alerts = []
if not isinstance(access, dict):
    access = {}

matching_alerts = []
for alert in alerts:
    if alert.get("source", {}).get("ip") == source_ip:
        matching_alerts.append(alert)
        continue
    for decision in (alert.get("decisions") or []):
        if decision.get("value") == source_ip:
            matching_alerts.append(alert)
            break

latest_alert = matching_alerts[0] if matching_alerts else None
active_decision = decisions[0] if decisions else None

print("== crowdsec 403 diagnosis ==")
print(f"- Source IP: {source_ip}")
print(f"- Active CrowdSec decision present: {'yes' if active_decision else 'no'}")

if active_decision:
    print(
        "- Active decision details: "
        f"{active_decision.get('scope')}:{active_decision.get('value')} | "
        f"{active_decision.get('type')} | "
        f"{active_decision.get('scenario')} | "
        f"created {active_decision.get('created_at')}"
    )

print(f"- Recent access-log matches for this IP: {access.get('total_recent_matches', 0)}")
print(f"- Recent 403 responses for this IP: {access.get('recent_403_count', 0)}")
print(
    "- Recent 403 responses with no upstream service "
    f"(strong CrowdSec middleware signal): {access.get('recent_middleware_403_count', 0)}"
)

if latest_alert:
    print(
        "- Latest matching alert: "
        f"{latest_alert.get('scenario')} | "
        f"created {latest_alert.get('created_at')} | "
        f"decisions {', '.join(d.get('type', '?') for d in (latest_alert.get('decisions') or [])) or 'none'}"
    )
    meta = {item.get("key"): item.get("value") for item in (latest_alert.get("meta") or [])}
    if meta:
        if "target_uri" in meta:
            print(f"- Alert target_uri sample: {meta['target_uri']}")
        if "user_agent" in meta:
            print(f"- Alert user_agent sample: {meta['user_agent']}")

print()
if active_decision and access.get("recent_middleware_403_count", 0) > 0:
    print("Diagnosis: likely CrowdSec middleware block in Traefik before Pangolin.")
elif active_decision:
    print("Diagnosis: CrowdSec decision exists for this IP, but recent middleware-style 403 evidence is incomplete.")
elif access.get("recent_middleware_403_count", 0) > 0:
    print("Diagnosis: recent middleware-style 403s exist, but no active CrowdSec decision is present right now.")
else:
    print("Diagnosis: this helper did not find the exact CrowdSec false-positive pattern.")

print()
print("Safest immediate workaround:")
print("- If this is a trusted fixed public IP, add it to a CrowdSec allowlist rather than disabling CrowdSec globally.")
print("- Keep the allowlist narrow to trusted home/office WAN IPs only.")
print("- Re-test after clearing the active decision for the trusted IP.")

print()
print("Useful follow-up commands:")
print(f"- Clear only this IP's current decision: ssh <host> 'docker exec crowdsec cscli decisions delete --ip {source_ip}'")
print("- List existing allowlists:")
for line in allowlists.splitlines():
    print(f"  {line}")

print()
print("Recent matching access-log entries:")
for row in access.get("recent", [])[-12:]:
    print(
        f"- {row.get('time')} | {row.get('status')} | {row.get('path')} | "
        f"service={row.get('service') or '-'} | ua={row.get('user_agent')}"
    )
PY
