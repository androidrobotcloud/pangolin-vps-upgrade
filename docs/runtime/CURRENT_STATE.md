# Current State

This file is the quickest current-state snapshot for the live `vm890` Pangolin environment.

Last verified: `2026-08-24`

## Live Target

- environment: `vm890`
- host: `hustler2025@vm890`
- stack path: `/home/hustler2025/docker/pangolin-vps`
- canonical dashboard URL: `https://pangolin.pang.androidrobot.cloud`

## Live Versions

- Pangolin: `fosrl/pangolin:ee-1.21.1`
- Gerbil: `fosrl/gerbil:1.5.0`
- Traefik: `traefik:v3.7.11`
- CrowdSec: `crowdsecurity/crowdsec:latest`
- Badger plugin: `v1.5.0`

## Live Edition

- Edition: `Enterprise Starter`
- License status: active on `vm890`
- License limits: `25 users`, `25 sites`
- Note: historical reports and older handoffs may still describe the prior Community deployment

## Live Health

- Pangolin internal health: healthy
- Canonical dashboard HTTPS: `HTTP/2 200`
- Pangolin stack services present: `pangolin`, `gerbil`, `traefik`, `crowdsec`

## Current Rollback Backups Kept

- `20260712-154853-pre-1.20.0.tar.gz`
- `20260712-155338-pre-v3.7.7.tar.gz`
- `20260824-164422-pre-ee-1.21.1.tar.gz`

## Current Disk Snapshot

- not re-verified in the `2026-07-27` sync session

## Use This With

- [vm890 runtime profile](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/runtime/vm890.md)
- [Repo contract](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/REPO_CONTRACT.md)
- [Read-only audit handoff](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-readonly-audit-v1.md)
- [Upgrade-readiness handoff](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-upgrade-readiness-audit-v1.md)

## Notes

- Historical handoffs and reports under `docs/handoffs/` and `docs/reports/` describe the state at the time they were created. Use this file first when you need the latest known live versions.
- The local offline clone of `vm890` now lives at [docs/runtime/vm890-backup.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/runtime/vm890-backup.md).
