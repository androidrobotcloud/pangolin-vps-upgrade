# VM890 Upgrade — Execution-Ready Runbook

> **Status: READY_FOR_EXECUTION_REVIEW**
>
> Preparation completed: 2026-09-18
> Planner: opencode (preparation task — no live mutation performed)
>
> This document is the authoritative handoff for the next execution agent.
> After owner approval of this commit, the agent should execute the stages
> in §11 in order, stopping at any gate that fails.

---

## Reconciliation with Historical Success

The repository's proven upgrade mechanism (from `2026-06-17-pangolin-staged-upgrade-v1-planner-proof.md` and `2026-08-24-tony-vps-community-to-enterprise-v1-run.md`):

1. **Community hops first** via `apply-pangolin-hop.sh`, then a **separate same-version Enterprise conversion** via `sed` replacing `fosrl/pangolin:1.21.1` → `fosrl/pangolin:ee-1.21.1`.
2. **Badger auto-migration is proven**: "Pangolin 1.19 migration updated the Badger version in Traefik config automatically" (historical report). Official docs confirm: Pangolin updates Badger config "when it still matches the default installer Traefik config."
3. **Backup-before-mutation + per-hop verification** via the helper chain.

**Key difference for this task:** vm890 is *already* Enterprise (`ee-1.21.1`). The historical Community→Enterprise conversion step does not apply. Instead, the Pangolin hop helper must preserve the `ee-` prefix across hops — which is now implemented (see §7).

**No new Enterprise-specific architecture was introduced.** The fix derives the edition prefix from the *current running image*, making the helper edition-agnostic and safe for both Community and Enterprise.

---

## 1. Target Environment and Identity Proof

- **Environment ID:** `vm890`
- **Spec:** `specs/environments/vm890.conf`
- **SSH:** `hustler2025@vm890`
- **Stack path:** `/home/hustler2025/docker/pangolin-vps`
- **Canonical URL:** `https://pangolin.pang.androidrobot.cloud`
- **Identity proof (live):** `hostname` → `vm890` ✓

---

## 2. Current Verified State (live, 2026-09-18)

| Component | Running image |
|---|---|
| Pangolin | `docker.io/fosrl/pangolin:ee-1.21.1` |
| Gerbil | `docker.io/fosrl/gerbil:1.5.0` |
| Traefik | `docker.io/traefik:v3.7.11` |
| CrowdSec | `crowdsecurity/crowdsec:latest` |
| Badger plugin | `v1.5.0` (in `config/traefik/traefik_config.yml`) |
| Newt | not present |

- Pangolin internal health: `{"message":"Healthy"}`
- Canonical dashboard: `HTTP/2 200`
- Edition: Enterprise Starter, license active, 25 users / 25 sites

---

## 3. Final Verified Stable Target Versions

| Component | Target | Type | Source |
|---|---|---|---|
| Pangolin | `ee-1.23.0` | 2 minor hops via `ee-1.22.2` | GitHub release 2026-09-16 + Docker Hub confirmed |
| Gerbil | `1.5.1` | Patch | GitHub release 2026-08-31 (1.5.2 tag exists but no release → conservative) |
| Traefik | `v3.7.13` | Patch | GitHub release 2026-09-04 + Docker Hub confirmed |
| Badger | auto-updated by Pangolin migration (verify ≥v1.6.0) | — | Official docs + historical proof |
| CrowdSec | `latest` (unchanged) | — | — |

**Docker Hub image existence verified (no pull):**
- `fosrl/pangolin:ee-1.22.2` ✓
- `fosrl/pangolin:ee-1.23.0` ✓
- `fosrl/gerbil:1.5.1` ✓
- `traefik:v3.7.13` ✓

---

## 4. Exact Enterprise Image Hops

```
docker.io/fosrl/pangolin:ee-1.21.1
  → docker.io/fosrl/pangolin:ee-1.22.2   (hop 1)
  → docker.io/fosrl/pangolin:ee-1.23.0   (hop 2)
```

**Edition safety:** The `apply-pangolin-hop.sh` helper now derives the edition prefix from the *current running image*. Since vm890 runs `ee-1.21.1`, every target is constructed as `ee-<version>`. It is **impossible** for the helper to produce a Community image from an Enterprise starting point (proven by simulation in §9).

---

## 5. Badger Decision and Evidence

**Decision: Rely on Pangolin's auto-migration. Do NOT manually pre-update Badger config.**

**Evidence:**
1. Official docs: "If a release includes a Badger update, Pangolin tries to update the Traefik config when it still matches the default Pangolin installer Traefik config."
2. Historical proof: Pangolin 1.19 migration auto-updated Badger to v1.4.1 on this environment (2026-06-17 report).
3. vm890's `traefik_config.yml` uses the **default installer format** (`experimental.plugins.badger.version`) — confirmed via read-only inspection.

**Why not manual first?** A manual Badger config edit + Traefik restart is an unnecessary extra mutation and restart. The migration handles it. Instead, `verify-pangolin-badger.sh` runs **after** each Pangolin hop and STOPS if the Badger version is below the minimum for the new Pangolin version (≥v1.6.0 for 1.22+).

**If auto-migration fails** (verification catches this): manual edit of `config/traefik/traefik_config.yml` + `docker compose restart traefik` + re-verify.

---

## 6. Backup Coverage After the Fix

**Persistent state on vm890** (confirmed via read-only filesystem inspection — there is **no `app-data/` directory**):
- `docker-compose.yml` — compose definition
- `config/db/db.sqlite` — Pangolin database
- `config/key` — encryption key
- `config/letsencrypt/acme.json` — TLS certificates
- `config/traefik/traefik_config.yml` — reverse proxy config + Badger version
- `config/config.yml` — Pangolin main config
- `config/crowdsec/` — Crowdsec config + DB

**Backup helper coverage:** `create-pangolin-backup.sh` archives `docker-compose.yml` + `config/` (and `app-data/` if present). For vm890 this captures **all** persistent state. Verified: existing backup `20260824-164422-pre-ee-1.21.1.tar.gz` contains all 6 critical paths.

**New:** `verify-pangolin-backup.sh` confirms a tarball contains all critical paths before proceeding. A missing path is a STOP condition.

---

## 7. Blockers Resolved

| # | Blocker | Resolution |
|---|---|---|
| 1 | Enterprise image-tag handling | `apply-pangolin-hop.sh` + `verify-pangolin-version.sh` now derive edition prefix from current image |
| 2 | Stale staged-upgrade spec | Rewritten: `EXPECTED_*` = current live state, `PANGOLIN_HOPS="1.22.2 1.23.0"` |
| 3 | Stale Gerbil companion spec | `GERBIL_HOPS="1.5.1"` |
| 4 | Stale Traefik companion spec | `TRAEFIK_HOPS="v3.7.13"` |
| 5 | Backup omits app-data | Not applicable — vm890 has no app-data dir; helper now conditionally includes app-data if present |
| 6 | Badger upgrade behaviour | Rely on auto-migration; verify with `verify-pangolin-badger.sh` post-hop |

---

## 8. Helper Changes

### `bin/apply-pangolin-hop.sh`
- Derives edition prefix (`ee-` or `""`) from current compose image tag
- Constructs target as `${PANGOLIN_IMAGE_REPO}:${edition_prefix}${TARGET_VERSION}`
- Python version parser strips prefix before comparison
- Downgrade protection preserved; edition now preserved by construction
- Reports full target image in pass message

### `bin/verify-pangolin-version.sh`
- Derives edition prefix from current compose image
- Builds expected image with correct prefix

### `bin/create-pangolin-backup.sh` / `bin/create-stack-backup.sh`
- Conditionally includes `app-data/` if present (forward-compatible)
- `config/` + `docker-compose.yml` always included

### `bin/end-to-end-pangolin-staged-upgrade-v1.sh`
- Per-hop backup verification (remote `tar -tzf` critical-path check)
- Per-hop `verify-pangolin-badger.sh` after each Pangolin hop
- Updated stale report text

### New helpers
- **`bin/verify-pangolin-backup.sh`** — verifies a backup tarball contains all 6 critical paths
- **`bin/verify-pangolin-badger.sh`** — verifies Badger plugin version meets minimum for running Pangolin version
- **`bin/verify-target-image.sh`** — confirms a target image tag exists on Docker Hub without pulling (uses specific-tag HTTP endpoint + manifest-inspect fallback)

---

## 9. Dry-Run / Read-Only Proof Results

### Identity & spec preflight (live vm890)
```
[pass] Hostname matches: vm890
[pass] Stack path exists: /home/hustler2025/docker/pangolin-vps
[pass] Required compose services present: pangolin gerbil traefik crowdsec
[pass] Expected image tags found
[pass] Dashboard URL matches runtime profile
[pass] Base domain matches runtime profile
[pass] Traefik network mode matches expected topology
```
Profile check passes against live vm890 with the corrected staged-upgrade spec.

### Runtime verification (live vm890)
```
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services
```

### Edition-prefix simulation (local)
```
docker.io/fosrl/pangolin:ee-1.21.1 -> docker.io/fosrl/pangolin:ee-1.22.2  [OK]
docker.io/fosrl/pangolin:ee-1.22.2 -> docker.io/fosrl/pangolin:ee-1.23.0  [OK]
Community: fosrl/pangolin:1.21.1 -> fosrl/pangolin:1.22.2  [OK]
```

### Downgrade protection (Python parser)
```
forward hop 1.21->1.22: allowed
forward hop 1.22->1.23: allowed
DOWNGRADE 1.23->1.22: REFUSED
```

### Backup verification
- Good tarball (all 6 paths): pass
- Bad tarball (missing db.sqlite): fail ✓
- Existing vm890 backup: all 6 critical paths present ✓

### Badger verification (live vm890)
```
Pangolin: ee-1.21.1
Badger:    v1.5.0
Minimum Badger required: v1.4.0
[pass] Badger v1.5.0 meets minimum v1.4.0 for Pangolin ee-1.21.1
```

### Target image existence (no pull)
```
[fosrl/pangolin:ee-1.22.2] pass (Docker Hub HTTP 200)
[fosrl/pangolin:ee-1.23.0] pass (Docker Hub HTTP 200)
[fosrl/gerbil:1.5.1] pass (Docker Hub HTTP 200)
[traefik:v3.7.13] pass (registry manifest inspect)
```

### Companion specs
- Gerbil companion: profile check passes ✓
- Traefik companion: profile check passes ✓

### Helper syntax
All 8 modified/new helpers pass `bash -n` syntax check.

---

## 10. Companion Helper Note

The companion update helpers (`apply-gerbil-hop.sh`, `apply-traefik-hop.sh`) do a full `docker compose down` + `up -d`. The runbook notes a narrow restart is preferable for Traefik patch hops, but the existing full-restart behavior is **previously proven** and the task instructs: "Do not make this change merely for elegance if it creates new risk; prefer previously proven behaviour." These are left unchanged. The Gerbil/Traefik companion end-to-end orchestrators already include per-hop backup + version verify + runtime verify and require no modification for this preparation.

---

## 11. Expected Live Upgrade Sequence

Execute in order. **STOP at any failed gate.** Each `[MUTATING]` step must not be run until owner authorises execution.

### STAGE 0 — Preflight [READ ONLY]
```bash
./bin/check-vm890-profile.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-target-image.sh docker.io/fosrl/pangolin:ee-1.22.2
./bin/verify-target-image.sh docker.io/fosrl/pangolin:ee-1.23.0
./bin/verify-target-image.sh docker.io/fosrl/gerbil:1.5.1
./bin/verify-target-image.sh docker.io/traefik:v3.7.13
```
**STOP if:** hostname ≠ vm890, stack path missing, images don't match current live state, any target image not found upstream.

### STAGE 1 — Backup checkpoint [MUTATING]
```bash
B1=$(./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2)
ssh hustler2025@vm890 "cd /home/hustler2025/docker/pangolin-vps && tar -tzf pangolin-vps-backups/$B1 | grep -q 'config/db/db.sqlite$'"
```
**STOP if:** tarball missing or critical paths absent.

### STAGE 2 — Pangolin hop ee-1.21.1 → ee-1.22.2 [MUTATING]
```bash
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2
./bin/verify-pangolin-badger.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
```
**STOP if:** version mismatch, Badger below v1.6.0, health not "Healthy", HTTPS ≠ 200.

### STAGE 3 — Backup + hop ee-1.22.2 → ee-1.23.0 [MUTATING]
```bash
B2=$(./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0)
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0
./bin/verify-pangolin-badger.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
```
**STOP if:** any check fails.

### STAGE 4 — Gerbil companion 1.5.0 → 1.5.1 [MUTATING]
```bash
./bin/end-to-end-pangolin-gerbil-companion-update-v1.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
```
**STOP if:** version mismatch, health fail, Gerbil logs show config/peer failures.

### STAGE 5 — Traefik companion v3.7.11 → v3.7.13 [MUTATING]
```bash
./bin/end-to-end-pangolin-traefik-companion-update-v1.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
```
**STOP if:** version mismatch, health fail, Traefik logs show startup/parsing errors.

### STAGE 6 — Final environment verification [READ ONLY]
```bash
./bin/check-vm890-profile.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
# Manual: log into dashboard, test representative site/resource, review logs
```

### STAGE 7 — Runtime documentation update + execution report [MUTATING — local only]
- Update `docs/runtime/CURRENT_STATE.md` versions + date
- Update `docs/runtime/vm890.md` versions + sanity run section
- Write `docs/reports/<date>-vm890-upgrade-execution.md` with hop sequence + backup filenames
- Do NOT change `docs/ENVIRONMENTS.md` (versions are not a material environment-level field)

---

## Rollback Decision Points

| If this fails | Roll back to |
|---|---|
| Stage 2 (hop to 1.22.2) | Restore `$B1` tarball: `docker compose down && tar -xzpf $B1 -C <stack> && docker compose up -d` |
| Stage 3 (hop to 1.23.0) | Restore `$B2` tarball |
| Stage 4 (Gerbil) | Restore Gerbil companion backup |
| Stage 5 (Traefik) | Restore Traefik companion backup |

Rollback = restore the matching pre-hop tarball (docker-compose.yml + config/) and `docker compose up -d`. Note: if a DB migration ran before failure, also restore `config/db/db.sqlite` from the tarball.

---

## 12. Remaining Blockers

**None for execution.** All 6 planning blockers are resolved. This commit is **READY_FOR_EXECUTION_REVIEW**.

---

*Preparation completed from live vm890 state (2026-09-18) and authoritative upstream sources. No live mutation performed.*
