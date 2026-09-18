# Runtime Profile: vm890-backup

This file records the local offline clone of the live `vm890` Pangolin stack.

Last verified: `2026-07-27`

## Local Target

- Colima profile: `vm890-backup`
- nested Incus guest: `pangolin-vm890-backup`
- guest stack path: `/home/hustler2025/docker/pangolin-vps`
- purpose: offline local clone of the live `vm890` stack
- current power state after sync: `Stopped`

## Synced State

Synced from live `vm890` on `2026-07-27`.

- Pangolin: `fosrl/pangolin:1.20.0`
- Gerbil: `fosrl/gerbil:1.4.2`
- Traefik: `traefik:v3.7.7`
- CrowdSec: `crowdsecurity/crowdsec:latest`

## Drift Note

- This offline clone currently reflects the older Community-era `2026-07-27` snapshot.
- Live `vm890` has since moved ahead to Pangolin Enterprise Starter on `ee-1.21.1`.
- Do not assume parity with live until this local clone is re-synced.

## Rollback Points

- Incus snapshot: `pre-sync-20260727`
- in-guest tar backup: `/home/hustler2025/pangolin-sync-backups/pre-sync-20260727-stack.tar.gz`
- preserved pre-sync stack tree: `/home/hustler2025/docker/pangolin-vps.pre-sync-20260727`

## Important Distinction

- `vm890-backup` is the local offline clone of the live VPS.
- `incus-lan` is a separate local lab profile and is not the `vm890` clone.

## Notes

- The sync replaced the stale local stack tree with a fresh export from `hustler2025@vm890`.
- The synced stack was started and validated on `2026-07-27`, then the `vm890-backup` Colima profile was stopped cleanly.
