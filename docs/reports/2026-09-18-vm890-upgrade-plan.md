# VM890 Upgrade Plan — Execution-Ready

> **Status: NOT_READY_FOR_UPGRADE**
>
> **Reason: helper and spec gaps must be fixed before execution. Plan itself is READY_FOR_OWNER_REVIEW.**
>
> Generated: 2026-09-18
> Planner: opencode (planning-only task — no mutation performed)

---

## 1. Target Environment and Identity Proof

- **Environment ID:** `vm890`
- **Spec:** `specs/environments/vm890.conf` — `ADAPTER=ssh_pangolin`, `SSH_TARGET=hustler2025@vm890`, `EXPECTED_HOSTNAME=vm890`, `STACK_PATH=/home/hustler2025/docker/pangolin-vps`
- **Canonical URL:** `https://pangolin.pang.androidrobot.cloud`
- **Identity proof (live):** `ssh hustler2025@vm890 hostname` → `vm890` ✓

---

## 2. Current Verified State (live, 2026-09-18)

| Component | Running image | Source |
|---|---|---|
| Pangolin | `docker.io/fosrl/pangolin:ee-1.21.1` | `docker inspect pangolin` + compose file |
| Gerbil | `docker.io/fosrl/gerbil:1.5.0` | `docker inspect gerbil` + compose file |
| Traefik | `docker.io/traefik:v3.7.11` | `docker inspect traefik` + compose file |
| CrowdSec | `crowdsecurity/crowdsec:latest` | compose images |
| Badger plugin | `v1.5.0` | `config/traefik/traefik_config.yml` |
| Newt | not present | prior environment scan |

- Pangolin internal health: `{"message":"Healthy"}`
- Canonical dashboard: `HTTP/2 200`
- Edition: Enterprise Starter, license active, 25 users / 25 sites

---

## 3. Latest Independently Verified Upstream Versions

| Component | Latest stable | Released | Source |
|---|---|---|---|
| Pangolin | `1.23.0` | 2026-09-16 | GitHub releases + Docker Hub `ee-1.23.0` |
| Gerbil | `1.5.1` (released) / `1.5.2` (tag only) | 2026-08-31 / 2026-09-18 | GitHub releases + Docker Hub |
| Badger | `v1.7.0` | 2026-08-24 | GitHub releases |
| Traefik | `v3.7.13` | 2026-09-04 | GitHub releases + Docker Hub |

> **Note on Gerbil 1.5.2:** Git tag exists but has no GitHub release yet (2026-09-18). Conservative target is `1.5.1` (released). `1.5.2` can be adopted once formally released.

---

## 4. Relevant Upstream Upgrade Requirements

From official Pangolin docs (`docs.pangolin.net/self-host/how-to-update`) and release notes:

1. **Incremental hops required** between major versions. Pangolin auto-runs DB migrations on startup in order from last-applied version.
2. **Failed migrations block startup** — server will not run.
3. **SQLite auto-backs up DB before migration** (unless `DISABLE_BACKUP_ON_MIGRATION=true`).
4. **Downgrading is sometimes impossible** — always back up config first.
5. **Pangolin 1.22.0+ (AI Gateway):** requires Badger `≥v1.6.0` and Gerbil `≥1.5.0` for AI gateway resources.
6. **Badger auto-update:** If release includes Badger change, Pangolin tries to update Traefik config when it matches the default installer config. Otherwise operator must update Badger manually.
7. **Backup `config` directory** before every update.

### Breaking changes by hop
| Hop | Relevant changes |
|---|---|
| `1.21.1 → 1.22.2` | AI Gateway introduced (new feature, opt-in). Badger ≥v1.6.0 required for AI gateway paths. DB migrations for gateway tables. |
| `1.22.2 → 1.23.0` | Self-service HA (Enterprise), multi-server-admin, Newt→Pangolin Site rename (cosmetic). |
| Gerbil `1.5.0 → 1.5.1` | Patch — no breaking changes documented. |
| Traefik `v3.7.11 → v3.7.13` | Same-line patch — no breaking changes documented. |
| Badger `v1.5.0 → v1.7.0` | Traefik plugin only — no DB impact. |

---

## 5. Compatibility / Dependency Analysis

### Proposed final state
| Component | Target |
|---|---|
| Pangolin | `ee-1.23.0` (Enterprise) |
| Gerbil | `1.5.1` |
| Traefik | `v3.7.13` |
| Badger | `v1.7.0` |
| CrowdSec | `latest` (unchanged) |

### Cross-component requirements
- Pangolin 1.23.0 → AI gateway (if used) needs Badger ≥v1.6.0 ✓ (v1.7.0 satisfies)
- Pangolin 1.23.0 → private AI gateway needs Gerbil ≥1.5.0 ✓ (1.5.1 satisfies)
- Newt: **not installed on vm890** — irrelevant for this control-plane upgrade.
- CrowdSec: `latest`, no pin, no action.

### ⚠️ Enterprise image naming issue (CRITICAL — see §7)
Current compose uses `docker.io/fosrl/pangolin:ee-1.21.1`. The `PANGOLIN_IMAGE_REPO` in specs is `docker.io/fosrl/pangolin`, and helpers construct targets as `${repo}:${version}` → `docker.io/fosrl/pangolin:1.22.2`. But the Enterprise image tag is `ee-1.22.2`, not `1.22.2`. The helpers would pull the **Community** image, not Enterprise. This must be fixed before execution.

---

## 6. Existing Helper Audit

### `bin/create-pangolin-backup.sh` / `bin/create-stack-backup.sh`
- **What it does:** Creates `YYYYMMDD-HHMMSS-pre-<label>.tar.gz` in `$BACKUP_DIR` containing `docker-compose.yml` and `config/` via an alpine helper container.
- **Required spec vars:** `SSH_TARGET`, `STACK_PATH`, `BACKUP_DIR`
- **Spec match:** ✓ (vm890 specs have these)
- **Backup verification:** `test -f` after creation
- **Failure behavior:** `set -euo pipefail` — exits on any failure
- **Rollback behavior:** None automated — tarball is the rollback artifact
- **Gap:** Does **not** back up `app-data/` (SQLite DB, Let's Encrypt certs, etc.). Pangolin's internal SQLite migration backup partially mitigates this, but a complete backup should include `app-data/`.

### `bin/apply-pangolin-hop.sh`
- **What it does:** Reads current compose image + runtime image, refuses downgrade (Python version check), does `docker compose down` + `docker compose pull pangolin` + `docker compose up -d`.
- **Required spec vars:** `SSH_TARGET`, `STACK_PATH`, `PANGOLIN_IMAGE_REPO`
- **Target construction:** `${PANGOLIN_IMAGE_REPO}:${TARGET_VERSION}` → `docker.io/fosrl/pangolin:1.22.2`
- **⚠ GAP:** Enterprise images are tagged `ee-1.22.2`. This helper will produce the **wrong image** for Enterprise. **MUST be fixed.**
- **Python version parser:** strips `v` prefix, splits on `-`. Works on `1.22.2` but would break on `ee-1.22.2`.
- **Failure behavior:** `set -euo pipefail`
- **No rollback:** relies on pre-hop backup

### `bin/verify-pangolin-version.sh`
- **What it does:** Confirms compose image == runtime image == `${PANGOLIN_IMAGE_REPO}:${EXPECTED_VERSION}`, then calls `verify-vm890-runtime.sh`.
- **⚠ GAP:** Same Enterprise image naming issue — expected image would be Community, not Enterprise.

### `bin/apply-gerbil-hop.sh`
- **What it does:** Same pattern as pangolin hop but for Gerbil. `docker compose down` + `pull gerbil` + `up -d`.
- **Required spec vars:** `SSH_TARGET`, `STACK_PATH`, `GERBIL_IMAGE_REPO`
- **Target:** `docker.io/fosrl/gerbil:1.5.1` — ✓ correct (no Enterprise prefix issue)

### `bin/verify-gerbil-version.sh`
- Confirms compose + runtime match expected, calls `verify-vm890-runtime.sh`

### `bin/apply-traefik-hop.sh`
- Same pattern for Traefik. `docker compose down` + `pull traefik` + `up -d`.
- **Required spec vars:** `SSH_TARGET`, `STACK_PATH`, `TRAEFIK_IMAGE_REPO`
- **Target:** `docker.io/traefik:v3.7.13` — ✓ correct
- **Note:** Runbook prefers narrow restart (`up -d traefik`) for patch hops, but helper does full down/up. Acceptable but causes wider restarts.

### `bin/verify-traefik-version.sh`
- Confirms compose + runtime match, checks Traefik logs for errors/fatal/panic, calls `verify-vm890-runtime.sh`

### `bin/check-vm890-profile.sh`
- **Pre-flight gate:** hostname, stack path, expected services, expected images, dashboard URL, base domain, Traefik network mode
- **Requires** `EXPECTED_PANGOLIN_IMAGE`, `EXPECTED_GERBIL_IMAGE`, `EXPECTED_TRAEFIK_IMAGE` to match live state

### `bin/verify-vm890-runtime.sh`
- **Runtime gate:** internal Pangolin health contains "Healthy", canonical URL returns `HTTP/2 200` (retries 6× with 5s sleep), compose shows healthy services

### `bin/end-to-end-pangolin-staged-upgrade-v1.sh`
- Orchestrates: profile check → pre-runtime → for each hop: backup → apply → version verify → runtime verify → write report
- Uses `PANGOLIN_HOPS` from spec

### `bin/verify-pangolin-upgrade-readiness.sh`
- Read-only upstream check via `git ls-remote` + Python analysis. Confirmed versions independently.

### Backup artifacts already on vm890
```
20260704-135502-pre-1.19.4.tar.gz
20260704-135822-pre-v3.7.6.tar.gz
20260712-154853-pre-1.20.0.tar.gz
20260712-155338-pre-v3.7.7.tar.gz
20260824-143033-pre-1.21.1.tar.gz
20260824-143422-pre-1.4.3.tar.gz
20260824-143647-pre-1.5.0.tar.gz
20260824-143916-pre-v3.7.11.tar.gz
20260824-164422-pre-ee-1.21.1.tar.gz   ← latest (pre-Enterprise-conversion)
```

---

## 7. Helper / Spec Gaps That Must Be Fixed First

### GAP 1 (BLOCKER): Enterprise image naming in Pangolin helpers
**Files:** `bin/apply-pangolin-hop.sh`, `bin/verify-pangolin-version.sh`, `specs/pangolin-staged-upgrade-v1.vm890.conf`

**Problem:** Helpers build target as `docker.io/fosrl/pangolin:1.22.2` but Enterprise image is `docker.io/fosrl/pangolin:ee-1.22.2`. Would pull Community edition.

**Required fix (one of):**
- (a) Add `PANGOLIN_EDITION_TAG=ee-` to spec and update helpers to use `${PANGOLIN_IMAGE_REPO}:${PANGOLIN_EDITION_TAG}${TARGET_VERSION}`, OR
- (b) Pass full target versions including `ee-` prefix to helpers (e.g. `apply-pangolin-hop.sh spec ee-1.22.2`) and adjust Python parser to strip `ee-` before version comparison.

### GAP 2 (BLOCKER): Stale staged-upgrade spec
**File:** `specs/pangolin-staged-upgrade-v1.vm890.conf`

**Current (wrong):**
```
EXPECTED_PANGOLIN_IMAGE=fosrl/pangolin:1.18.3
EXPECTED_GERBIL_IMAGE=fosrl/gerbil:1.4.0
EXPECTED_TRAEFIK_IMAGE=traefik:v3.6.16
PANGOLIN_HOPS="1.18.4 1.19.2"
```

**Required:**
```
EXPECTED_PANGOLIN_IMAGE=fosrl/pangolin:ee-1.21.1
EXPECTED_GERBIL_IMAGE=fosrl/gerbil:1.5.0
EXPECTED_TRAEFIK_IMAGE=traefik:v3.7.11
PANGOLIN_HOPS="1.22.2 1.23.0"
```

Profile check will **fail** against current live state with the stale spec.

### GAP 3 (BLOCKER): Stale companion specs
**Files:**
- `specs/pangolin-gerbil-companion-update-v1.vm890.conf`: `GERBIL_HOPS="1.5.0"` → must be `GERBIL_HOPS="1.5.1"`
- `specs/pangolin-traefik-companion-update-v1.vm890.conf`: `TRAEFIK_HOPS="v3.7.11"` → must be `TRAEFIK_HOPS="v3.7.13"`

### GAP 4 (NON-BLOCKER): No Badger helper
Badger is a Traefik plugin version in `config/traefik/traefik_config.yml`, not a container. There is no `apply-badger-hop.sh`. Badger upgrade must be done by:
1. Editing `version: v1.5.0` → `version: v1.7.0` in `config/traefik/traefik_config.yml`
2. Restarting Traefik (or full stack)

**Recommendation:** Since Pangolin 1.22+ requires Badger ≥v1.6.0 for AI gateway, and the official docs say Pangolin auto-updates Badger config when it matches the default installer config, update Badger config to `v1.7.0` **before** the first Pangolin hop. This is a manual step.

### GAP 5 (NON-BLOCKER): Backup excludes app-data
Backups cover `docker-compose.yml` and `config/` only. They do **not** cover `app-data/` (SQLite DB, certificates). Pangolin's internal SQLite migration backup mitigates DB risk, but `app-data/` should ideally be included for full coverage.

---

## 8. Backup Proof

**Mechanism:** `bin/create-pangolin-backup.sh` / `bin/create-stack-backup.sh`
- Creates `YYYYMMDD-HHMMSS-pre-<label>.tar.gz` in `/home/hustler2025/docker/pangolin-vps-backups/`
- Contents: `docker-compose.yml` + `config/` tree
- Created inside an alpine container with `-v $STACK_PATH:/src:ro` (handles root-owned files)
- Verified via `test -f` after creation

**Pre-existing backups present** (see §6) — the latest is `20260824-164422-pre-ee-1.21.1.tar.gz`.

**What is NOT backed up:** `app-data/` (SQLite DB, Let's Encrypt certs). Mitigated by Pangolin's internal SQLite migration backup.

**Recommendation:** Add `app-data/` to backup scope before execution.

---

## 9. Rollback Proof

**Per-hop rollback (documented in runbook §10):**
```bash
# If hop to 1.22.2 fails:
cd /home/hustler2025/docker/pangolin-vps
docker compose down
tar -xzpf /home/hustler2025/docker/pangolin-vps-backups/<pre-1.22.2-tarball>.tar.gz
docker compose up -d
```

**Rollback points = per-hop backup tarballs.** Each hop creates a backup labeled with the target version. Restore the tarball matching the failed hop.

**Evidence of match to current architecture:** Backup method (`create-pangolin-backup.sh`) is unchanged since last successful use (2026-08-24 Enterprise conversion). Backup dir exists and is populated.

**⚠️ Caveat:** Backups do not include `app-data/`. If a DB migration has run and failed, restoring config alone may not be sufficient — the SQLite DB backup (auto-created by Pangolin) must also be restored. Pangolin stores this in `app-data/` — another reason to include `app-data/` in backups.

**No automatic rollback.** Operator must decide and execute manually.

---

## 10. Proposed Staged Upgrade Sequence

### Architecture decision: separate Pangolin core from companions

The repo historically keeps Pangolin core migrations separate from companion updates. This remains correct:
1. Pangolin hops involve DB migrations (riskier, need tighter verification)
2. Companions are image swaps (simpler)
3. Each gets its own backup + verification gate

### Ordering rationale
1. **Pangolin first** — highest risk (DB migrations), must be stable before touching companions
2. **Gerbil before Traefik** — Gerbil shares network namespace with Traefik; update the backend first
3. **Traefik last** — reverse proxy; update after backend is stable
4. **Badger** — update config before Pangolin hops (so 1.22.x AI gateway migration finds compatible version)

### Stages

| Stage | What | Est. downtime | Verification gate |
|---|---|---|---|
| 0 | Preflight (read-only) | none | profile + runtime pass |
| 1 | Backup checkpoint | none | tarball exists |
| 2 | Update Badger config v1.5.0→v1.7.0 + restart Traefik | ~30s | config file correct, Traefik healthy |
| 3 | Pangolin 1.21.1 → 1.22.2 | 1-3 min (migrations) | version + runtime + health |
| 4 | Verify gate — STOP or continue | none | all checks green |
| 5 | Pangolin 1.22.2 → 1.23.0 | 1-3 min (migrations) | version + runtime + health |
| 6 | Verify gate — STOP or continue | none | all checks green |
| 7 | Gerbil 1.5.0 → 1.5.1 | ~30s | version + runtime + Gerbil logs |
| 8 | Traefik v3.7.11 → v3.7.13 | ~30s | version + runtime + Traefik logs |
| 9 | Final full verification | none | dashboard + health + HTTPS |

---

## 11. Exact Commands That WOULD Be Run

> **Prerequisite:** All gaps from §7 must be fixed first. Specs updated, Enterprise image naming resolved, Badger helper created or manual Badger step documented.

### STAGE 0 — Preflight [READ ONLY]

```bash
./bin/check-vm890-profile.sh specs/pangolin-staged-upgrade-v1.vm890.conf     [READ ONLY]
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf   [READ ONLY]
./bin/verify-pangolin-upgrade-readiness.sh specs/pangolin-upgrade-readiness-audit-v1.vm890.conf  [READ ONLY]
```

**STOP if:** any check fails, hostname ≠ vm890, stack path missing, or images don't match expected pre-hop values.

### STAGE 1 — Backup checkpoint [MUTATING — DO NOT RUN YET]

```bash
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2   [MUTATING — DO NOT RUN YET]
```

**Verify:** `ssh hustler2025@vm890 ls -lh /home/hustler2025/docker/pangolin-vps-backups/*pre-1.22.2*`

### STAGE 2 — Badger config update [MUTATING — DO NOT RUN YET]

```bash
# Update Badger plugin version in Traefik config
ssh hustler2025@vm890 "sed -i 's/version: v1.5.0/version: v1.7.0/' /home/hustler2025/docker/pangolin-vps/config/traefik/traefik_config.yml"   [MUTATING]
# Verify
ssh hustler2025@vm890 "grep 'version:' /home/hustler2025/docker/pangolin-vps/config/traefik/traefik_config.yml"   [READ ONLY]
# Restart Traefik to load new plugin
ssh hustler2025@vm890 "cd /home/hustler2025/docker/pangolin-vps && docker compose restart traefik"   [MUTATING]
```

**STOP if:** config edit fails, grep doesn't show `v1.7.0`, Traefik doesn't return healthy.

### STAGE 3 — Pangolin hop 1.21.1 → 1.22.2 [MUTATING — DO NOT RUN YET]

```bash
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2   [MUTATING]
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2       [MUTATING]
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2  [READ ONLY]
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf            [READ ONLY]
```

**STOP if:** version mismatch, health not "Healthy", HTTPS ≠ 200, migration errors in logs.

### STAGE 4 — Verify gate [READ ONLY]

```bash
ssh hustler2025@vm890 "docker exec pangolin curl -fsS http://localhost:3001/api/v1/"   [READ ONLY]
curl -k -I -sS https://pangolin.pang.androidrobot.cloud | sed -n '1,12p'              [READ ONLY]
ssh hustler2025@vm890 "cd /home/hustler2025/docker/pangolin-vps && docker compose ps" [READ ONLY]
```

**STOP if:** any check fails. Roll back to Stage 3 backup.

### STAGE 5 — Pangolin hop 1.22.2 → 1.23.0 [MUTATING — DO NOT RUN YET]

```bash
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0   [MUTATING]
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0       [MUTATING]
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0  [READ ONLY]
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf            [READ ONLY]
```

**STOP if:** version mismatch, health not "Healthy", HTTPS ≠ 200.

### STAGE 6 — Verify gate [READ ONLY]

```bash
ssh hustler2025@vm890 "docker exec pangolin curl -fsS http://localhost:3001/api/v1/"   [READ ONLY]
curl -k -I -sS https://pangolin.pang.androidrobot.cloud | sed -n '1,12p'              [READ ONLY]
```

**STOP if:** any check fails. Roll back to Stage 5 backup.

### STAGE 7 — Gerbil 1.5.0 → 1.5.1 [MUTATING — DO NOT RUN YET]

```bash
./bin/create-stack-backup.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.5.1  [MUTATING]
./bin/apply-gerbil-hop.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.5.1      [MUTATING]
./bin/verify-gerbil-version.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.5.1 [READ ONLY]
./bin/verify-vm890-runtime.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf        [READ ONLY]
```

**Gerbil health indicators (from logs):** remote config fetched, WireGuard interface created, peers added, HTTP server on :3004.

**STOP if:** version mismatch, health fail, Gerbil logs show config/peer failures.

### STAGE 8 — Traefik v3.7.11 → v3.7.13 [MUTATING — DO NOT RUN YET]

```bash
./bin/create-stack-backup.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.13  [MUTATING]
./bin/apply-traefik-hop.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.13      [MUTATING]
./bin/verify-traefik-version.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.13 [READ ONLY]
./bin/verify-vm890-runtime.sh specs/pangolin-traefik-companion-update-v1.vm890.conf           [READ ONLY]
```

**STOP if:** version mismatch, health fail, Traefik logs show startup/parsing errors.

### STAGE 9 — Final full verification [READ ONLY]

```bash
./bin/check-vm890-profile.sh specs/pangolin-staged-upgrade-v1.vm890.conf      [READ ONLY]
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf    [READ ONLY]
# Manual: log into dashboard, test representative site/resource, check Gerbil peers
```

---

## 12. Verification Gates and Explicit STOP Conditions

| Gate | Check | STOP trigger |
|---|---|---|
| Pre-flight | profile + runtime | hostname, stack, services, images mismatch |
| Pre-flight | runtime verify | health not "Healthy", HTTPS ≠ 200 |
| Per-hop | version verify | compose/runtime image ≠ expected |
| Per-hop | runtime verify | health not "Healthy", HTTPS ≠ 200 |
| Per-hop | backup exists | tarball missing before mutation |
| Companion | service logs | Gerbil config/peer failures; Traefik parse/startup errors |
| Final | full profile + runtime | any regression |

**Design principle:** backup → verify backup → mutate → verify → STOP or continue. Never verify-everything-at-the-end.

---

## 13. Expected Downtime / Service Impact

| Stage | Impact | Duration |
|---|---|---|
| Badger update | Traefik restart → brief HTTPS interruption | ~30s |
| Pangolin hops | Full stack down/up + DB migration | 1-3 min per hop |
| Gerbil update | Full stack down (network namespace shared) | ~30s |
| Traefik update | Full stack down/up | ~30s |

**Total estimated downtime:** ~5-10 minutes across all stages, with HTTPS interruption during each restart. Traefik may briefly fail HTTPS checks during restart even when healthy moments later (observed in prior runs).

---

## 14. Documentation Changes Expected After Successful Execution

- **`docs/runtime/CURRENT_STATE.md`:** update all version fields, "Last verified" date, backup list
- **`docs/runtime/vm890.md`:** update "Verified Running Versions", "profile verified" date, sanity run section, helper example versions
- **`docs/reports/`:** dated execution report with hop sequence + backup filenames
- **`docs/ENVIRONMENTS.md`:** **NO CHANGE** — a software version update does not materially change any standard environment field (owner, purpose, components, state unchanged)

---

## 15. Remaining Uncertainties

1. **AI Gateway on vm890:** Unknown whether AI gateway resources are in use. If they are, Badger ≥v1.6.0 is mandatory for the 1.22.x migration. The plan updates Badger to v1.7.0 beforehand, which satisfies this regardless. **Flag for operator confirmation.**
2. **Gerbil 1.5.2:** Git tag exists but no GitHub release. Plan targets 1.5.1 (released). Revisit if 1.5.2 is formally released before execution.
3. **app-data backup gap:** Backups don't include SQLite DB / certs. Pangolin's internal migration backup is the safety net. Operator should decide whether to add `app-data/` to backup scope.
4. **Enterprise image fix approach:** GAP 1 requires choosing between fix (a) `EDITION_TAG` variable or (b) passing `ee-` prefixed versions. Both are low-risk code changes but must be reviewed.

---

## 16. Final Statement

**NOT_READY_FOR_UPGRADE**

**Blockers to resolve before execution:**

1. Fix Enterprise `ee-` image naming in Pangolin helpers (GAP 1)
2. Rewrite stale `pangolin-staged-upgrade-v1.vm890.conf` (GAP 2)
3. Update companion spec HOPS (GAP 3)

**Non-blockers (recommended but optional):**
- Create Badger update helper or document manual step (GAP 4)
- Add `app-data/` to backup scope (GAP 5)

**Plan is READY_FOR_OWNER_REVIEW.** Once the three blockers are fixed and re-verified, the upgrade can proceed using the staged command sequence in §11.

---

*Plan generated from live vm890 state (2026-09-18) and authoritative upstream sources. No mutation was performed during planning.*
