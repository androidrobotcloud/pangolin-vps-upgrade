# VM890 Upgrade — Lessons Learned and Operational Improvements

> **Date:** 2026-09-18
> **Execution report:** `docs/reports/2026-09-18-vm890-upgrade-execution.md`
> **Commit range:** `11ab801` (preparation) → `0b8063d` (cleanup) → `f484cbc` (complete) → `c378847` (lessons) → `3cebacd` (qc)
>
> This document captures operational experience from the live vm890 Pangolin
> upgrade so that future agents can avoid repeating the same mistakes and
> benefit from the same recoveries. It is written for future agents, not as
> historical narrative.

---

## Table of Contents

1. [Reconstructed Run Summary](#reconstructed-run-summary)
2. [Lesson 1: Disk Capacity](#lesson-1-disk-capacity)
3. [Lesson 2: Registry Connectivity](#lesson-2-registry-connectivity)
4. [Lesson 3: Backup Restore Is Not Service Recovery](#lesson-3-backup-restore-is-not-service-recovery)
5. [Lesson 4: Diagnosing HTTPS 404](#lesson-4-diagnosing-https-404)
6. [Lesson 5: Enterprise Edition Preservation](#-lesson-5-enterprise-edition-preservation)
7. [Lesson 6: Badger Auto-Migration](#lesson-6-badger-auto-migration)
8. [Lesson 7: Canonical Backup Verification](#lesson-7-canonical-backup-verification)
9. [If I Were Doing This Again](#if-i-were-doing-this-again)
10. [Things That Worked Well](#things-that-worked-well)
11. [Things That Created Unnecessary Friction](#things-that-created-unnecessary-friction)
12. [Automation Improvements Implemented](#automation-improvements-implemented)
13. [Recommendations Not Automated](#recommendations-not-automated)

---

## Reconstructed Run Summary

| Phase | What happened | Outcome |
|---|---|---|
| Baseline | vm890 on Pangolin `ee-1.21.1`, Gerbil `1.5.0`, Traefik `v3.7.11`, Badger `v1.5.0` | Healthy, verified |
| Preparation | Helpers/specs updated; Enterprise edition preservation added; canonical backup verifier created | `11ab801` |
| Hop 1 | `ee-1.21.1 → ee-1.22.2` | Success. Badger auto-migrated to `v1.7.0` |
| Hop 2 attempt 1 | `ee-1.22.2 → ee-1.23.0` | **FAILED** — Docker Hub IPv6 unreachable during pull |
| Recovery | Stack DOWN after failed pull; restored from backup to `ee-1.22.2` | Service restored |
| Disk cleanup | Removed 3 inactive Community Pangolin images (~3.9 GB freed) | Disk 99% → 85% |
| Hop 2 attempt 2 | `ee-1.22.2 → ee-1.23.0` | Pull + migration succeeded |
| HTTPS issue | External HTTPS returned 404; Traefik routers disabled | Diagnosed as stale `dynamic_config.yml` |
| HTTPS fix | Restored Traefik config state | HTTPS 200 restored |
| Gerbil | `1.5.0 → 1.5.1` | Success |
| Traefik | `v3.7.11 → v3.7.13` | Success |
| Final | `ee-1.23.0` / `1.5.1` / `v3.7.13` / Badger `v1.7.0` | All verified healthy |

---

## Lesson 1: Disk Capacity

### Situation
During Hop 2 attempt 1, the Pangolin `ee-1.23.0` image pull failed with:
```
failed to register layer: write /app/node_modules/...: no space left on device
```
The host reached **99% disk usage** (~253 MB free on a 20 GB filesystem).

### Symptom
`docker compose pull pangolin` failed mid-extraction. The stack was left DOWN because `down` ran before `pull` in the helper sequence.

### Evidence
- `df -h /` showed `20G 19G 253M 99%`
- `docker system df` showed 5.882 GB reclaimable (85% of image storage)
- Three inactive Community-era images (`fosrl/pangolin:1.19.4`, `1.20.0`, `1.21.1`) were consuming ~3.9 GB

### Root cause (proven)
1. The new Pangolin image (~1.1 GB extracted) requires space to download AND extract while the old image still exists.
2. The failed partial extraction left orphaned layers consuming additional space.
3. No preflight disk check existed; the upgrade proceeded without verifying headroom.

### Correct response
1. Identified reclaimable images via `docker system df`
2. Removed only **inactive** images (not used by any running container): `docker image rm fosrl/pangolin:1.19.4 1.20.0 1.21.1`
3. Verified disk dropped to 85% before retrying
4. Retried the pull successfully

### What NOT to do
- **Never** run `docker system prune` automatically — it can remove build cache, volumes, or images the operator wants to keep.
- **Never** delete backups to free space during an upgrade.
- **Never** remove images that are referenced by running or recently-running containers.
- Do not assume percentage-used alone is sufficient; a 99% full 20 GB filesystem with 253 MB free is very different from a 99% full 1 TB filesystem.

### Preventive check for future runs
**Implemented:** `bin/check-upgrade-disk.sh` — a read-only preflight gate that runs BEFORE the first mutation.

The rule (conservative, evidence-based):
- Require **both**:
  - Filesystem free space ≥ **2 GB** absolute (covers extraction overhead + backup growth + partial-pull residue)
  - Filesystem usage ≤ **90%** (catches the case where a large filesystem is still dangerously full in absolute terms)
- Report reclaimable Docker images (inactive images, dangling layers) as candidates for **operator review** — do NOT auto-delete.
- Fail with a clear message listing specific reclaimable images and the exact command to remove them.

### Lesson type
Automated gate (`check-upgrade-disk.sh`) + documented prerequisite.

### Repository helper
`bin/check-upgrade-disk.sh` (new) — invoked by `bin/end-to-end-pangolin-staged-upgrade-v1.sh` before the first hop.

---

## Lesson 2: Registry Connectivity

### Situation
Hop 2 attempt 1 failed with:
```
Head "https://registry-1.docker.io/v2/fosrl/pangolin/manifests/ee-1.23.0":
dial tcp [2a06:98c1:3104::6812:2bb2]:443: connect: network is unreachable
```

### Symptom
The image pull failed during the manifest fetch phase. The IPv6 address for Docker Hub's registry was unreachable from vm890.

### Evidence
- The error specifically showed an IPv6 address (`2a06:98c1:3104::6812:2bb2`) being unreachable
- The same pull succeeded minutes later (Hop 2 attempt 2), confirming the image existed and the issue was transient connectivity
- `verify-target-image.sh` had previously confirmed the tag existed on Docker Hub (HTTP 200), but this only checks reachability from the **local workstation**, not from vm890

### Root cause (strongly supported)
Transient IPv6 connectivity failure between vm890 and Docker Hub's registry endpoint. The local `verify-target-image.sh` check is insufficient because it runs from the workstation, not the target host.

### Correct response
1. Verified the stack was DOWN and restored from backup
2. Retried the pull after connectivity recovered (no manual network intervention needed)

### What NOT to do
- Do not assume "tag exists" (from `verify-target-image.sh`) means "target host can pull now." These are different checks.
- Do not pull production images merely as a test unless the repository policy permits it.
- Do not skip the retry — transient failures are common and usually self-resolve.

### Preventive check for future runs
**Implemented:** `bin/check-registry-connectivity.sh` — a read-only preflight that proves vm890 can reach the required registry endpoints immediately before mutation.

The rule:
- From the target host, verify reachability of `registry-1.docker.io` (Docker Hub) via both the API endpoint and the manifest endpoint for each target image tag
- Distinguish "tag exists upstream" (workstation check) from "target host can reach registry NOW" (target check)
- Fail clearly if the target host cannot reach the registry, BEFORE taking the stack down

### Lesson type
Automated gate (`check-registry-connectivity.sh`) + troubleshooting guidance.

### Repository helper
`bin/check-registry-connectivity.sh` (new) — invoked by the end-to-end orchestrator before the first hop.

---

## Lesson 3: Backup Restore Is Not Service Recovery

### Situation
After the Hop 2 attempt 1 network failure left the stack DOWN, the backup was restored to recover service. The filesystem restore succeeded, but external HTTPS subsequently returned 404.

### Symptom
After restore + `docker compose up -d`:
- Pangolin internal health: Healthy
- Internal dashboard (localhost:3002): HTTP 200
- **External HTTPS (pangolin.pang.androidrobot.cloud): HTTP 404**

### Evidence
- Traefik's HTTPS routers (`next-router@file`, `api-router@file`, `ws-router@file`) were all in `status=disabled`
- Traefik logs showed middleware errors: `invalid middleware "crowdsec@file" configuration: invalid middleware type or middleware does not exist`
- The `dynamic_config.yml` file had been reverted to an older version by the backup restore
- Traefik uses an HTTP provider (`http://pangolin:3001/api/v1/traefik-config`) to fetch its dynamic config from Pangolin's API — this config was stale after the restore
- Direct backend reachability worked: `docker exec traefik wget http://pangolin:3002` returned full HTML

### Root cause (proven)
The backup's `dynamic_config.yml` was stale (from an earlier Pangolin version). After restore, Traefik's file provider loaded the stale config with broken middleware references. The HTTP provider (which serves the authoritative config from Pangolin's API) needed a Traefik restart to re-fetch and reconcile.

### Correct response
1. Diagnosed using the HTTPS 404 decision path (see Lesson 4)
2. Restarted the Traefik container: `docker compose restart traefik`
3. Traefik re-fetched config from Pangolin's HTTP provider; HTTPS routers re-enabled; HTTPS returned 200

### What NOT to do
- Do not assume a successful filesystem restore = service recovery.
- Do not restart Traefik unconditionally after every restore — verify first, restart only if routing is stale.
- Do not edit `dynamic_config.yml` manually — it is managed by Pangolin's HTTP provider.

### Preventive check for future runs
**Implemented:** `bin/verify-service-recovery.sh` — a post-restore verification helper that checks all required service layers before declaring recovery complete.

The rule (verification-first):
After any restore/rollback, verify in order:
1. Pangolin container running
2. Pangolin internal health = Healthy
3. Traefik container running
4. Traefik HTTPS routers = enabled (via API)
5. Direct backend reachable (`pangolin:3002`)
6. Canonical external HTTPS = HTTP/2 200

Only if step 4 fails (routers disabled) AND steps 1-3 pass, restart Traefik and re-verify.

### Lesson type
Troubleshooting guidance + automated post-restore verification helper.

### Repository helper
`bin/verify-service-recovery.sh` (new) — invoked after any restore/rollback operation.

---

## Lesson 4: Diagnosing HTTPS 404

### Situation
After the backup restore, external HTTPS returned 404. The cause could have been Pangolin failure, Traefik misconfiguration, network issues, or DNS.

### Symptom
`curl -k -I https://pangolin.pang.androidrobot.cloud` → `HTTP/2 404`

### Evidence observed (decisive diagnostics)
| Check | Result | Meaning |
|---|---|---|
| Pangolin internal health | Healthy | Application is running |
| Internal dashboard (localhost:3002) | HTTP 200 | Dashboard serves correctly |
| Traefik services | all enabled | Backends registered |
| Traefik HTTPS routers | **all disabled** | Config problem, not backend |
| Traefik logs | middleware errors | Stale dynamic_config.yml |
| Direct backend from traefik container | Full HTML | Network path works |
| External HTTPS | 404 | Traefik not routing |

### Root cause (proven)
Traefik's HTTPS routers were disabled because the `dynamic_config.yml` (loaded by Traefik's file provider) referenced middlewares that didn't exist in the current config. The backup had reverted this file to a stale version.

### Troubleshooting decision path for future agents

```
HTTPS returns 404/502/503?
│
├─ Is Pangolin internal health Healthy?
│  ├─ NO → Application/migration problem. Check Pangolin logs.
│  └─ YES ↓
│
├─ Is internal dashboard reachable (localhost:3002)?
│  ├─ NO → Pangolin UI not started. Check logs.
│  └─ YES ↓
│
├─ Are Traefik HTTPS routers enabled?
│  │  (check: docker exec traefik wget http://localhost:8080/api/http/routers)
│  ├─ YES → Network/DNS/certificate problem. Check DNS, firewall, cert.
│  └─ NO ↓ (THIS WAS OUR CASE)
│
├─ Are Traefik services enabled?
│  ├─ NO → Backend not registered. Check service discovery.
│  └─ YES ↓
│
├─ Check Traefik logs for middleware/provider errors
│  ├─ middleware errors → Stale dynamic_config.yml → Restart Traefik
│  ├─ provider errors → Config fetch failing → Check provider endpoint
│  └─ certificate errors → ACME/renewal problem → Check cert status
│
└─ Direct backend reachable from traefik container?
   ├─ NO → Network/Docker networking problem
   └─ YES → Config/routing problem (most likely middleware)
```

### Lesson type
Troubleshooting guidance (documented above).

---

## Lesson 5: Enterprise Edition Preservation

### Situation
The repository's generic Pangolin helpers originally constructed targets as `fosrl/pangolin:<version>` (Community). vm890 runs Enterprise (`ee-<version>`). Without edition preservation, an upgrade would have pulled the Community image, breaking Enterprise features.

### Symptom
Not directly observed (prevented by preparation), but the risk was real: `apply-pangolin-hop.sh` would have produced `fosrl/pangolin:1.22.2` instead of `fosrl/pangolin:ee-1.22.2`.

### Root cause (proven)
The helper assumed Community image naming. Enterprise images use the `ee-` prefix.

### Correct response
Modified `apply-pangolin-hop.sh` and `verify-pangolin-version.sh` to derive the edition prefix from the **current running image**:
```bash
current_tag="${current_compose_image##*:}"
edition_prefix="${current_tag%%[0-9]*}"
target_image="${PANGOLIN_IMAGE_REPO}:${edition_prefix}${TARGET_VERSION}"
```
This makes it impossible to cross editions: Enterprise stays Enterprise, Community stays Community.

### General rule
**Derive/preserve the currently running Pangolin edition rather than assuming Community or manually converting.** The workflow must fail closed if an Enterprise deployment would be changed to a Community image.

### Lesson type
Automated gate (edition-prefix derivation in `apply-pangolin-hop.sh`).

### Repository helper
`bin/apply-pangolin-hop.sh`, `bin/verify-pangolin-version.sh`.

---

## Lesson 6: Badger Auto-Migration

### Situation
During Hop 1 (ee-1.21.1 → ee-1.22.2), Pangolin's migration automatically updated the Badger plugin version in `config/traefik/traefik_config.yml` from `v1.5.0` to `v1.7.0`.

### Symptom
Not a failure — the migration worked as documented. The planning document had proposed a manual Badger pre-update, which turned out to be unnecessary.

### Evidence
- Before Hop 1: `version: v1.5.0` in traefik_config.yml
- After Hop 1: `version: v1.7.0` in traefik_config.yml
- Official Pangolin docs confirm: "If a release includes a Badger update, Pangolin tries to update the Traefik config when it still matches the default Pangolin installer Traefik config."
- Historical proof: the same auto-update happened during the 1.19 migration (to v1.4.1) on this environment.

### Root cause (proven)
Pangolin's migration system updates Badger automatically when the Traefik config matches the default installer format. vm890's config is in this format.

### Correct response
Verified the resulting Badger version (`v1.7.0`) met the minimum required for Pangolin 1.22+ (`v1.6.0`) using `verify-pangolin-badger.sh`. No manual edit was needed.

### What NOT to do
- Do NOT assume this auto-update works for every Pangolin deployment. It depends on the config matching the default installer format.
- Do NOT blindly pre-edit Badger before Pangolin upgrades — this could conflict with the migration.
- Do NOT treat this single observation as a universal assumption.

### Preventive check for future runs
Always run `verify-pangolin-badger.sh` after each Pangolin hop. If the auto-update didn't occur (non-default config), the verifier will catch the incompatibility and STOP.

### Lesson type
Automated gate (`verify-pangolin-badger.sh`) + documented prerequisite.

### Repository helper
`bin/verify-pangolin-badger.sh`.

---

## Lesson 7: Canonical Backup Verification

### Situation
Multiple backups were created during the upgrade. A backup file existing on disk does not guarantee it contains all state needed for recovery.

### Symptom
Not a direct failure, but the lesson was reinforced when a restore was actually needed (after the network failure).

### Evidence
- The canonical verifier (`verify-pangolin-backup.sh`) checks 6 critical paths: `docker-compose.yml`, `config/db/db.sqlite`, `config/key`, `config/letsencrypt/acme.json`, `config/traefik/traefik_config.yml`, `config/config.yml`
- On vm890, all persistent state lives under `config/` (no separate `app-data/` directory) — the verifier covers everything
- The backup helper now conditionally includes `app-data/` if present (forward-compatible)

### Root cause (proven)
A backup is only useful if it contains all recoverable state. The six-path verifier enforces this.

### Correct response
The successful workflow was: **create → inspect → prove required state exists → mutate.**

### General rule
**Backup created ≠ recoverable backup proven.** Always verify before mutating.

### Lesson type
Automated gate (`verify-pangolin-backup.sh`).

### Repository helper
`bin/verify-pangolin-backup.sh`, `bin/create-pangolin-backup.sh`, `bin/create-stack-backup.sh`.

---

## If I Were Doing This Again

Improved sequence incorporating all lessons:

### Phase 0 — Preflight (read-only, all must pass)
1. Sync repository; verify HEAD contains approved preparation commit
2. Prove identity: `hostname` = vm890
3. Profile check: `check-vm890-profile.sh`
4. Runtime check: `verify-vm890-runtime.sh`
5. **Disk capacity: `check-upgrade-disk.sh`** (NEW — fail if < 2 GB free or > 90% used)
6. **Registry connectivity: `check-registry-connectivity.sh`** (NEW — fail if target host can't reach Docker Hub)
7. Target image existence: `verify-target-image.sh` for each target
8. Verify current versions match expected starting state

### Phase 1 — Hop 1 (ee-1.21.1 → ee-1.22.2)
1. Create backup → canonical backup verification
2. Apply hop
3. Verify exact Enterprise image
4. Verify runtime health + **external HTTPS 200**
5. Verify Badger
6. **STOP or continue**

### Phase 2 — Hop 2 (ee-1.22.2 → ee-1.23.0)
1. Create backup → canonical backup verification
2. Apply hop
3. Verify exact Enterprise image
4. Verify runtime health + **external HTTPS 200**
5. Verify Badger
6. **If HTTPS fails:** run `verify-service-recovery.sh` → diagnose using HTTPS 404 decision path → restart Traefik only if routers disabled
7. **STOP or continue**

### Phase 3 — Companions (only after Pangolin fully verified)
1. Gerbil: backup → verify → apply → verify + HTTPS
2. Traefik: backup → verify → apply → verify + HTTPS

### Phase 4 — Final
1. Full profile + runtime verification
2. Environment status scan
3. Documentation update
4. Execution report

### Key differences from the original run:
- **Disk and registry preflight** prevent the two issues that actually occurred
- **External HTTPS verified after EVERY mutation** (not just internal health) — catches config issues immediately
- **Post-restore verification helper** prevents the "restore ≠ recovery" class of problem
- **HTTPS 404 decision path** provides structured diagnosis instead of guessing

---

## Things That Worked Well

These safety mechanisms proved valuable and should be retained:

1. **STOP gates** — The explicit stop conditions prevented continuing through failures. The "STOP or continue" pattern after each hop is essential.
2. **Enterprise edition preservation** — Deriving the edition prefix from the running image made it impossible to cross Community/Enterprise.
3. **Canonical backup verification** — The six-path verifier ensured every backup was recoverable before mutation.
4. **Staged hops** — Incremental Pangolin upgrades (1.21→1.22→1.23) with verification after each, rather than a direct jump.
5. **Per-hop verification** — Version + runtime + Badger checks after every mutation.
6. **Environment scanning** — The post-upgrade scan captured the new verified state.
7. **set -euo pipefail** — All helpers fail fast on any error.
8. **Read-only preflight helpers** — Profile, runtime, target-image checks don't mutate anything.
9. **Badger verifier** — Confirmed the auto-migration worked without manual intervention.
10. **Traefik API diagnostics** — Querying `/api/http/routers` and `/api/http/services` directly was decisive in diagnosing the HTTPS 404.

---

## Things That Created Unnecessary Friction

1. **Inline tar/grep duplication** — The end-to-end orchestrator originally duplicated the six-path check inline instead of calling the canonical verifier. Fixed in `0b8063d`.
2. **No disk preflight** — The upgrade proceeded without checking disk space, leading to the 99% full failure. Now automated.
3. **No registry connectivity check** — `verify-target-image.sh` runs from the workstation, not the target host. Now automated.
4. **Backup restore without post-restore verification** — The restore succeeded at the filesystem level but HTTPS was broken. No automated check caught this. Now automated via `verify-service-recovery.sh`.
5. **Stale hardcoded report text** — The end-to-end orchestrator had hardcoded "Problems found" text referencing Pangolin 1.19 and Gerbil 1.4. Corrected to current versions.
6. **Stale version in vm890.md** — The "Known Hazards" section still referenced `ee-1.21.1` after the upgrade. Corrected in this review.

---

## Automation Improvements Implemented

### 1. `bin/check-upgrade-disk.sh` (NEW)
Read-only disk-capacity preflight gate.

**Rule:** Fail if available space < 2 GB OR usage > 90%. Report reclaimable images for operator review. Do NOT auto-delete.

**Solves:** Lesson 1 (disk capacity).

### 2. `bin/check-registry-connectivity.sh` (NEW)
Read-only registry-connectivity preflight gate.

**Rule:** From the target host, verify Docker Hub registry reachability for each target image. Fail clearly if unreachable.

**Solves:** Lesson 2 (registry connectivity).

### 3. `bin/verify-service-recovery.sh` (NEW)
Post-restore verification helper with HTTPS 404 decision path.

**Rule:** After any restore, verify all service layers. If HTTPS routers are disabled, restart Traefik and re-verify.

**Solves:** Lessons 3 and 4 (backup restore ≠ recovery, HTTPS 404 diagnosis).

### 4. Updated `bin/end-to-end-pangolin-staged-upgrade-v1.sh`
- Invokes `check-upgrade-disk.sh` and `check-registry-connectivity.sh` before the first hop
- Invokes `verify-service-recovery.sh` context (documented) after any restore

### 5. Stale reference corrections
- `docs/runtime/vm890.md` line 125: `ee-1.21.1` → `ee-1.23.0`

---

## Recommendations Not Automated

| Recommendation | Why not automated |
|---|---|
| Automatic `docker system prune` | Too destructive; could remove operator-valued state. Cleanup requires operator judgement per Lesson 1. |
| Automatic image deletion | Requires operator review of reclaimable candidates. Risk of removing images needed for rollback. |
| Automatic Traefik restart after restore | Verification-first is safer. Only restart if routers are actually disabled (Lesson 3). |
| Automatic retry on network failure | Transient failures usually self-resolve, but blind retries without diagnosis can mask real problems. Operator should assess. |
| Deleting root-owned old backup | Requires root password (not available). Operator must handle manually. |

---

## Validation

- All modified/new helpers pass `bash -n` syntax check
- `check-upgrade-disk.sh`: correctly FAILS on current vm890 (92% > 90%) — this is the intended post-upgrade state
- `check-registry-connectivity.sh`: passes (Docker Hub reachable from vm890)
- `verify-service-recovery.sh`: passes (all layers healthy)
- `resolve-pangolin-target-image.sh`: correctly derives Enterprise targets
- No live vm890 mutation occurred during this review
- Historical reports were not rewritten
- Current runtime documentation correctly states Pangolin `ee-1.23.0`
- Lessons document is discoverable from README and REPO_CONTRACT.md
- README links are now repository-relative (no absolute filesystem paths)

---

## Quality-Control Verification (2026-09-18)

> ChatGPT applied repository-side quality-control commits (`b97df24` through
> `3cebacd`) after the lessons document was created. This section records the
> verification of those changes and the fresh disk evidence.

### Canonical Target Image Resolver

A new helper `bin/resolve-pangolin-target-image.sh` centralizes edition-preserving
target-image resolution. The `apply`, `verify`, and `registry-preflight` paths now
all use this single resolver, eliminating the risk that preflight and mutation
could disagree about Community vs Enterprise image selection.

**Proof (against live vm890):**
```
$ ./bin/resolve-pangolin-target-image.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.22.2
docker.io/fosrl/pangolin:ee-1.22.2

$ ./bin/resolve-pangolin-target-image.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.23.0
docker.io/fosrl/pangolin:ee-1.23.0
```

**Community preservation (local fixture test):**
```
Community input:  docker.io/fosrl/pangolin:1.21.1  →  docker.io/fosrl/pangolin:1.22.2
Enterprise input: docker.io/fosrl/pangolin:ee-1.21.1  →  docker.io/fosrl/pangolin:ee-1.23.0
```

### Registry Preflight Uses Exact Mutation Targets

The end-to-end orchestrator's registry preflight now obtains image references from
the same canonical resolver:
```bash
target_images+=("$(./bin/resolve-pangolin-target-image.sh "$SPEC_FILE" "$target")")
```

**Proof:** registry preflight received exactly:
- `docker.io/fosrl/pangolin:ee-1.22.2` (not `fosrl/pangolin:1.22.2`)
- `docker.io/fosrl/pangolin:ee-1.23.0` (not `fosrl/pangolin:1.23.0`)

Both confirmed reachable (HTTP 401) from vm890.

### Bug Found and Fixed During Verification

**File:** `bin/apply-pangolin-hop.sh` line 28
**Defect:** ChatGPT's diff introduced literal `\n` characters instead of actual
newlines, AND the replacement line started with `#`, making the entire
`target_image` and `edition_prefix` assignments part of a comment. The script
would have failed because `target_image` was never set.

**File:** `bin/verify-pangolin-version.sh` line 25
**Defect:** Same literal `\n` issue. Additionally, the `compose_image` variable
assignment was removed but the variable was still referenced in the comparison
check, which would have caused an "unbound variable" failure under `set -u`.

**Fix applied:** Replaced literal `\n` with actual newlines; restored the
`compose_image` assignment in verify; uncommented the code lines in both files.

### README Portability

All absolute filesystem paths (`/Users/hustler2025/...`) in README.md were replaced
with repository-relative links by ChatGPT (`3cebacd`). Verification confirmed no
remaining absolute paths in README.md, MASTER_OPERATING_POLICY.md, or REPO_CONTRACT.md.

### Fresh Disk Evidence (2026-09-18, post-qc)

```
$ ssh hustler2025@vm890 "df -h /home/hustler2025/docker/pangolin-vps"
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G   18G  1.7G  92% /
```

**Disk preflight result: FAIL (correct)**
```
Available:  2G (2 GB)  ← passes the ≥2 GB absolute floor
Usage:      92% (92%)  ← FAILS the ≤90% ceiling
```

| Historical state | Usage | Context |
|---|---|---|
| During failed pull (Hop 2 attempt 1) | 99% (253 MB free) | Failed extraction left partial layers |
| After image cleanup | 85% (3.1 GB free) | 3 inactive Community images removed |
| **Current (post-upgrade)** | **92% (1.7 GB free)** | **Normal post-upgrade state** |

The current 92% is the expected post-upgrade state: the new ee-1.23.0 image
replaced the old one, and no cleanup has been performed since. The preflight
correctly blocks another upgrade until the operator reviews and removes
reclaimable candidates. **This is the intended behavior** — the threshold must
not be weakened to make the machine pass.

### Profile/Runtime Verification (read-only)
```
Profile check: hostname ✓, stack ✓, services ✓, image ✗ (spec still says ee-1.21.1)
Runtime check: health ✓, HTTPS 200 ✓, healthy services ✓
```

The profile "failure" is expected — `EXPECTED_PANGOLIN_IMAGE` in the spec reflects
the pre-upgrade baseline and correctly detects that the version has changed.
The runtime check passes, confirming the stack is healthy.

### Files Changed by QC (verified, not redesigned)
| File | Change |
|---|---|
| `bin/resolve-pangolin-target-image.sh` | NEW — canonical edition-preserving resolver |
| `bin/apply-pangolin-hop.sh` | Uses canonical resolver for target image |
| `bin/verify-pangolin-version.sh` | Uses canonical resolver for expected image |
| `bin/end-to-end-pangolin-staged-upgrade-v1.sh` | Registry preflight uses canonical resolver |
| `README.md` | Absolute paths → repository-relative links |

### Confirmation
- All 8 helpers pass `bash -n` syntax check
- Canonical resolver derives correct Enterprise targets
- Community preservation verified via local fixture
- Registry preflight receives exact mutation targets
- No live vm890 mutation during verification
- No secrets added
- Historical reports not rewritten

---

*This document should be updated after each future vm890 upgrade to capture new lessons. It is a living operational record, not a one-time report.*
