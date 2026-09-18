Task: environment-status-scan-v1
Environment ID: vm890
Scan timestamp: 2026-09-18T13:52:52Z
Result: passed — environment healthy, no drift from baseline

## Identity verification
- Expected hostname: vm890
- Actual hostname: vm890
- Match: yes
- Stack path exists: /home/hustler2025/docker/pangolin-vps

## Runtime state (live)

### Services
| Service | Image | Status | Health |
|---|---|---|---|
| pangolin | fosrl/pangolin:ee-1.21.1 | Up 11 hours | healthy |
| gerbil | fosrl/gerbil:1.5.0 | Up 11 hours | running |
| traefik | traefik:v3.7.11 | Up 11 hours | running |
| crowdsec | crowdsecurity/crowdsec:latest | Up 11 hours | healthy |

### Components
- Pangolin: ee-1.21.1 (Enterprise Starter, license active, 25 users / 25 sites)
- Gerbil: 1.5.0
- Traefik: v3.7.11
- CrowdSec: latest
- Badger plugin: v1.5.0
- Newt: not present on this environment

### Health
- Pangolin internal (http://localhost:3001/api/v1/): {"message":"Healthy"}
- Canonical dashboard (https://pangolin.pang.androidrobot.cloud): HTTP/2 200

## Baseline comparison (vs 2026-08-24)

| Component | Baseline (2026-08-24) | Current (2026-09-18) | Status |
|---|---|---|---|
| Pangolin | ee-1.21.1 | ee-1.21.1 | unchanged |
| Gerbil | 1.5.0 | 1.5.0 | unchanged |
| Traefik | v3.7.11 | v3.7.11 | unchanged |
| CrowdSec | latest | latest | unchanged |
| Badger | v1.5.0 | v1.5.0 | unchanged |
| Health | healthy / 200 | healthy / 200 | unchanged |

Conclusion: no drift. The environment is exactly as documented.

## Upstream update availability (INFORMATION ONLY — not installed)

| Component | Installed | Latest upstream | Update available | Proposed path |
|---|---|---|---|---|
| Pangolin | ee-1.21.1 | 1.23.0 | YES — crosses minor (1.21 -> 1.23) | 1.22.2 -> 1.23.0 |
| Gerbil | 1.5.0 | 1.5.1 | YES — same line patch | 1.5.1 |
| Badger | v1.5.0 | v1.7.0 | YES — crosses minor (v1.5 -> v1.7) | v1.6.1 -> v1.7.0 |
| Traefik | v3.7.11 | v3.7.13 | YES — same line patch | v3.7.13 |

Notes:
- Official Pangolin guidance requires incremental hops and config backup before each hop.
- Companion service changes should be kept separate from Pangolin core migrations.
- Badger is tied to Traefik middleware behavior — keep separate from Pangolin core work.

## Problems found
None. Environment is healthy and matches its documented baseline.

## Unverifiable facts
None.

## Environment: vm890
Scan timestamp: 2026-09-18T13:52:52Z
Result: evidence-collected

Previous baseline: docs/runtime/CURRENT_STATE.md (2026-08-24), docs/runtime/vm890.md (2026-08-24)
