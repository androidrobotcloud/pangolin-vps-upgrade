# VM890 Upgrade Execution Report — 2026-09-18

> **Status: STOPPED_AT_GATE**
>
> Hop 1 (Pangolin ee-1.21.1 → ee-1.22.2) completed and verified successfully.
> Hop 2 (Pangolin ee-1.22.2 → ee-1.23.0) image pull and migration completed, but
> external HTTPS routing returns 404. STOP triggered by canonical HTTPS failure gate.

---

## Execution Result: STOPPED_AT_GATE

**Gate that stopped execution:** Canonical HTTPS check returns HTTP 404 (expected HTTP/2 200).

## What Was Completed Successfully

### Hop 1: Pangolin ee-1.21.1 → ee-1.22.2 ✓
- Backup: `20260918-163102-pre-1.22.2.tar.gz` (78.9 MB, all 6 critical paths verified)
- Edition preserved: `docker.io/fosrl/pangolin:ee-1.22.2` (Enterprise)
- Pangolin version verify: pass
- Runtime health: Healthy + HTTPS 200 + healthy services
- Badger auto-migrated: v1.5.0 → v1.7.0 (verified ≥ v1.6.0)

### Hop 2: Pangolin ee-1.22.2 → ee-1.23.0 (partial)
- Backup attempt 1: `20260918-163442-pre-1.23.0.tar.gz` (pull failed - network unreachable)
- Rollback to ee-1.22.2 from backup (required after network failure left stack DOWN)
- Disk cleanup: removed 3 inactive Community images (1.19.4, 1.20.0, 1.21.1) → freed ~3.9 GB
- Backup attempt 2: `20260918-163915-pre-1.23.0.tar.gz` (79.1 MB, all 6 paths verified)
- Image pull + extraction: SUCCESS
- Container start: SUCCESS, migration completed, health: **Healthy**
- Edition preserved: `docker.io/fosrl/pangolin:ee-1.23.0` (Enterprise) ✓
- Pangolin version verify: pass (compose + runtime both ee-1.23.0)
- Internal health: Healthy (http://localhost:3001/api/v1/ → {"message":"Healthy"})
- Internal dashboard: HTTP 200 (http://localhost:3002)

## What Failed

### External HTTPS routing: HTTP 404
The canonical dashboard URL `https://pangolin.pang.androidrobot.cloud` returns **HTTP 404** instead of 200.

**Root cause identified:** Traefik HTTPS routers (`next-router@file`, `api-router@file`, `ws-router@file`) are all in `status=disabled` state. Traefik logs show:

```
error: invalid middleware "crowdsec@file" configuration: invalid middleware type or middleware does not exist
error: invalid middleware "badger@http" configuration: invalid middleware type or middleware does not exist
```

The `dynamic_config.yml` middleware references are broken. This occurred after the backup restore (required after the network failure during Hop 2 attempt 1 left the stack DOWN). The `crowdsec` middleware IS defined in the file, but Traefik cannot resolve the `crowdsec@file` reference, suggesting a config loading/plugin issue triggered by the container restart sequence.

**Evidence:**
- `docker exec traefik wget http://localhost:8080/api/http/routers` → all websecure routers `status=disabled`
- `docker exec traefik wget http://localhost:8080/api/http/services` → all services `status=enabled`
- Direct backend reachability: `docker exec traefik wget http://pangolin:3002` → returns full dashboard HTML (backend IS reachable)
- Internal health: Healthy, migration completed successfully

## Exact Final State (live vm890)

| Component | Version/Image | Status |
|---|---|---|
| Pangolin | `docker.io/fosrl/pangolin:ee-1.23.0` | running, healthy |
| Gerbil | `docker.io/fosrl/gerbil:1.5.0` | running |
| Traefik | `docker.io/traefik:v3.7.11` | running |
| CrowdSec | `crowdsecurity/crowdsec:latest` | running, healthy |
| Badger plugin | `v1.7.0` | auto-migrated |
| Pangolin internal health | Healthy | ✓ |
| Internal dashboard (localhost:3002) | HTTP 200 | ✓ |
| External HTTPS dashboard | **HTTP 404** | ✗ STOP |

## Backup Files Created

1. `20260918-163102-pre-1.22.2.tar.gz` — recovery point: ee-1.22.2 (Hop 1 pre-mutation)
2. `20260918-163442-pre-1.23.0.tar.gz` — recovery point: ee-1.22.2 (Hop 2 attempt 1, failed pull)
3. `20260918-163915-pre-1.23.0.tar.gz` — recovery point: ee-1.22.2 (Hop 2 attempt 2, current)

## Disk Cleanup Performed

- Removed inactive Docker images: `fosrl/pangolin:1.19.4`, `fosrl/pangolin:1.20.0`, `fosrl/pangolin:1.21.1` (~3.9 GB freed)
- Disk after cleanup: 85% used (3.1 GB free) — sufficient for image pull

## Verification Gate Results

| Gate | Result |
|---|---|
| Preflight: identity = vm890 | ✓ pass |
| Preflight: profile check | ✓ pass |
| Preflight: runtime check | ✓ pass |
| Preflight: starting versions match | ✓ pass |
| Preflight: target images exist upstream | ✓ pass |
| Hop 1: backup creation | ✓ pass |
| Hop 1: canonical backup verification | ✓ pass (6/6 paths) |
| Hop 1: apply hop to ee-1.22.2 | ✓ pass |
| Hop 1: version = ee-1.22.2 (Enterprise) | ✓ pass |
| Hop 1: runtime health | ✓ pass |
| Hop 1: Badger ≥ v1.6.0 (got v1.7.0) | ✓ pass |
| Hop 2: backup creation | ✓ pass |
| Hop 2: canonical backup verification | ✓ pass (6/6 paths) |
| Hop 2: image pull + extract | ✓ pass |
| Hop 2: container start + migration | ✓ pass |
| Hop 2: version = ee-1.23.0 (Enterprise) | ✓ pass |
| Hop 2: internal health | ✓ pass |
| **Hop 2: canonical HTTPS (external)** | **✗ FAIL — HTTP 404** |

## Recovery Options

The service is healthy and running ee-1.23.0 internally. Two recovery paths:

**Option A — Fix HTTPS routing (recommended):** The issue is Traefik middleware config in `dynamic_config.yml`. Restarting the Pangolin container may regenerate the correct config:
```bash
ssh hustler2025@vm890 "cd /home/hustler2025/docker/pangolin-vps && docker compose restart pangolin"
```
Then re-verify HTTPS. If that doesn't work, the `crowdsec` plugin loading order may need investigation.

**Option B — Roll back to ee-1.22.2:** Restore from backup `20260918-163915-pre-1.23.0.tar.gz` (contains ee-1.22.2 compose + config):
```bash
ssh hustler2025@vm890 "cd /home/hustler2025/docker/pangolin-vps && docker compose down && tar -xzpf /home/hustler2025/docker/pangolin-vps-backups/20260918-163915-pre-1.23.0.tar.gz --overwrite && docker compose up -d"
```

## Companion Upgrades (not reached)

- Gerbil 1.5.0 → 1.5.1: NOT EXECUTED (blocked by Hop 2 STOP)
- Traefik v3.7.11 → v3.7.13: NOT EXECUTED (blocked by Hop 2 STOP)

## Warnings

- The backup restore required after the network failure may have caused the Traefik config issue. Future runs should re-verify HTTPS immediately after any backup restore before proceeding to the next hop.
- The `16-moodle-router@http` references `badger@http` middleware that doesn't exist (likely a stale external service registration), but this does not affect the Pangolin dashboard routing.
