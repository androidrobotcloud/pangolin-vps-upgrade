#!/usr/bin/env bash

set -euo pipefail

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

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "[fail] Missing required command: $1" >&2
    exit 1
  }
}

for cmd in ssh curl python3 git; do
  need_cmd "$cmd"
done

remote() {
  ssh "$SSH_TARGET" "$@"
}

PANGOLIN_CURRENT="$(remote "docker inspect pangolin --format '{{.Config.Image}}'")"
GERBIL_CURRENT="$(remote "docker inspect gerbil --format '{{.Config.Image}}'")"
TRAEFIK_CURRENT="$(remote "docker inspect traefik --format '{{.Config.Image}}'")"
BADGER_CURRENT="$(remote "cd '$STACK_PATH' && awk '/badger:/,/crowdsec:/ { if (\$1==\"version:\") {gsub(/\"/, \"\", \$2); print \$2; exit} }' config/traefik/traefik_config.yml")"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

git ls-remote --tags --refs "$PANGOLIN_GIT_URL" > "$TMPDIR/pangolin_tags.txt"
git ls-remote --tags --refs "$GERBIL_GIT_URL" > "$TMPDIR/gerbil_tags.txt"
git ls-remote --tags --refs "$BADGER_GIT_URL" > "$TMPDIR/badger_tags.txt"
git ls-remote --tags --refs "$TRAEFIK_GIT_URL" > "$TMPDIR/traefik_tags.txt"

python3 - "$PANGOLIN_CURRENT" "$GERBIL_CURRENT" "$TRAEFIK_CURRENT" "$BADGER_CURRENT" "$TMPDIR" "$PANGOLIN_UPDATE_DOC_URL" <<'PY'
import re
import sys

pangolin_current, gerbil_current, traefik_current, badger_current, tmpdir, update_doc_url = sys.argv[1:7]

def strip_repo(image: str) -> str:
    return image.rsplit(":", 1)[-1]

def parse_tag(tag: str):
    nums = re.findall(r"\d+", tag.lstrip("v"))
    if len(nums) < 3:
        raise ValueError(f"Unsupported tag format: {tag}")
    return tuple(int(p) for p in nums[:3])

def tag_prefix(tag: str):
    nums = re.findall(r"\d+", tag.lstrip("v"))
    if len(nums) < 2:
        raise ValueError(f"Unsupported tag format: {tag}")
    return ".".join(nums[:2])

def normalize(tag: str):
    return tag.lstrip("v")

def read_tags(name: str):
    tags = []
    with open(f"{tmpdir}/{name}", "r", encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            _sha, ref = line.split("\t", 1)
            tag = ref.rsplit("/", 1)[-1]
            if not re.match(r"^v?\d+\.\d+\.\d+$", tag):
                continue
            tags.append(tag)
    return tags

def same_line_latest(current_tag: str, tags):
    current_prefix = tag_prefix(current_tag)
    candidates = [tag for tag in tags if tag_prefix(tag) == current_prefix]
    return max(candidates, key=parse_tag) if candidates else current_tag

def hop_path(current_tag: str, stable):
    current_ver = parse_tag(current_tag)
    latest_overall = max(stable, key=parse_tag)
    latest_ver = parse_tag(latest_overall)
    if current_ver >= latest_ver:
        return []
    by_minor = {}
    for tag in stable:
        ver = parse_tag(tag)
        if ver < current_ver or ver > latest_ver:
            continue
        by_minor[(ver[0], ver[1])] = max(by_minor.get((ver[0], ver[1]), tag), tag, key=parse_tag)
    ordered = [by_minor[k] for k in sorted(by_minor)]
    ordered = [t for t in ordered if parse_tag(t) > current_ver]
    return ordered

def status(current_tag: str, line_latest: str, overall_latest: str):
    if normalize(current_tag) == normalize(overall_latest):
        return "current"
    if normalize(current_tag) == normalize(line_latest):
        return "current-on-line-behind-overall"
    if normalize(line_latest) == normalize(overall_latest):
        return "behind-current-line"
    return "behind-current-line-and-overall"

pangolin_tags = read_tags("pangolin_tags.txt")
gerbil_tags = read_tags("gerbil_tags.txt")
badger_tags = read_tags("badger_tags.txt")
traefik_tags = read_tags("traefik_tags.txt")

pangolin_line_latest = same_line_latest(strip_repo(pangolin_current), pangolin_tags)
gerbil_line_latest = same_line_latest(strip_repo(gerbil_current), gerbil_tags)
traefik_line_latest = same_line_latest(strip_repo(traefik_current), traefik_tags)
badger_line_latest = same_line_latest(badger_current, badger_tags)

pangolin_overall = max(pangolin_tags, key=parse_tag)
gerbil_overall = max(gerbil_tags, key=parse_tag)
traefik_overall = max(traefik_tags, key=parse_tag)
badger_overall = max(badger_tags, key=parse_tag)

pangolin_path = hop_path(strip_repo(pangolin_current), pangolin_tags)
gerbil_path = hop_path(strip_repo(gerbil_current), gerbil_tags)
traefik_path = hop_path(strip_repo(traefik_current), traefik_tags)
badger_path = hop_path(badger_current, badger_tags)

print("== pangolin upgrade readiness ==")
print("Official upstream sources:")
print(f"- Pangolin update docs: {update_doc_url}")
print(f"- Pangolin latest stable tag: {pangolin_overall}")
print(f"- Gerbil latest stable tag: {gerbil_overall}")
print(f"- Badger latest stable tag: {badger_overall}")
print(f"- Traefik latest stable tag: {traefik_overall}")
print()
print("Version audit:")
print(f"- Pangolin: current {strip_repo(pangolin_current)} | current-line latest {pangolin_line_latest} | overall latest {pangolin_overall} | status {status(strip_repo(pangolin_current), pangolin_line_latest, pangolin_overall)}")
print(f"- Gerbil: current {strip_repo(gerbil_current)} | current-line latest {gerbil_line_latest} | overall latest {gerbil_overall} | status {status(strip_repo(gerbil_current), gerbil_line_latest, gerbil_overall)}")
print(f"- Badger: current {badger_current} | current-line latest {badger_line_latest} | overall latest {badger_overall} | status {status(badger_current, badger_line_latest, badger_overall)}")
print(f"- Traefik: current {strip_repo(traefik_current)} | current-line latest {traefik_line_latest} | overall latest {traefik_overall} | status {status(strip_repo(traefik_current), traefik_line_latest, traefik_overall)}")
print()
print("Read-only proposed version paths:")
print(f"- Pangolin: {' -> '.join(pangolin_path) if pangolin_path else 'none'}")
print(f"- Gerbil: {' -> '.join(gerbil_path) if gerbil_path else 'none'}")
print(f"- Badger: {' -> '.join(badger_path) if badger_path else 'none'}")
print(f"- Traefik: {' -> '.join(traefik_path) if traefik_path else 'none'}")
print()
print("Breaking changes and gotchas to review before mutating work:")
print("- Official update docs say to back up the config directory and update incrementally between versions.")
print("- Existing repo runbook says to keep companion service changes separate from Pangolin migrations where possible.")
if parse_tag(strip_repo(pangolin_current)) < parse_tag("1.19.0") <= parse_tag(pangolin_overall):
    print("- Pangolin 1.19 official release summary adds browser-based SSH, RDP, and VNC, improved Pangolin SSH, automatic site updates, labels, and resource policies.")
    print("- Inference from official summaries: no explicit breaking change is highlighted for 1.19, but it is still a minor-version jump and should be validated with representative site, SSH, and browser-access checks after upgrade.")
if normalize(strip_repo(traefik_current)).startswith("3.6") and normalize(traefik_overall).startswith("3.7"):
    print("- Traefik is behind both on the current 3.6 line and the overall 3.7 line; treat any Traefik move as a separate companion task.")
if normalize(badger_current) != normalize(badger_overall):
    print("- Badger plugin is behind the latest release; because it is tied to Traefik middleware behavior, keep it separate from Pangolin core migrations.")
PY
