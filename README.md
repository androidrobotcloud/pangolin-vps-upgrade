# Pangolin VPS Upgrade

This repo has bounded AI-operable workflows:

- `pangolin-readonly-audit-v1`
- `pangolin-upgrade-readiness-audit-v1`
- `pangolin-staged-upgrade-v1`
- `pangolin-gerbil-companion-update-v1`
- `pangolin-traefik-companion-update-v1`
- `tony-vps-community-to-enterprise-v1`

These workflows are intentionally narrow. They give a worker deterministic audit, staged-upgrade, and edition-conversion paths for live Pangolin stacks (`vm890`, `tony_vps`) without rediscovering the repo or improvising commands. Local lab environments (`incus-lan`) are also staged from this repo.

## Current Workflow Target

- environment: `vm890`
- host: `hustler2025@vm890`
- stack path: `/home/hustler2025/docker/pangolin-vps`
- canonical dashboard URL: `https://pangolin.pang.androidrobot.cloud`
- latest live snapshot: [docs/runtime/CURRENT_STATE.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/runtime/CURRENT_STATE.md)
- local offline clone: [docs/runtime/vm890-backup.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/runtime/vm890-backup.md)

## Start Here

Read these local contract files in order:

1. [docs/MASTER_OPERATING_POLICY.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/MASTER_OPERATING_POLICY.md)
2. [docs/REPO_CONTRACT.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/REPO_CONTRACT.md)
3. [docs/runtime/CURRENT_STATE.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/runtime/CURRENT_STATE.md)
4. [docs/runtime/vm890.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/runtime/vm890.md)
5. [docs/handoffs/pangolin-readonly-audit-v1.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-readonly-audit-v1.md) or [docs/handoffs/pangolin-upgrade-readiness-audit-v1.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-upgrade-readiness-audit-v1.md)
6. [docs/handoffs/pangolin-staged-upgrade-v1.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-staged-upgrade-v1.md) or [docs/handoffs/pangolin-gerbil-companion-update-v1.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-gerbil-companion-update-v1.md)
7. [docs/handoffs/pangolin-traefik-companion-update-v1.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/handoffs/pangolin-traefik-companion-update-v1.md)

## Helper Path

Run from repo root:

```bash
./bin/check-vm890-profile.sh specs/pangolin-readonly-audit-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-readonly-audit-v1.vm890.conf
./bin/end-to-end-pangolin-readonly-audit-v1.sh specs/pangolin-readonly-audit-v1.vm890.conf
./bin/verify-pangolin-upgrade-readiness.sh specs/pangolin-upgrade-readiness-audit-v1.vm890.conf
./bin/end-to-end-pangolin-upgrade-readiness-audit-v1.sh specs/pangolin-upgrade-readiness-audit-v1.vm890.conf
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.21.1
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.21.1
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.21.1
./bin/end-to-end-pangolin-staged-upgrade-v1.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.5.0
./bin/apply-gerbil-hop.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.5.0
./bin/verify-gerbil-version.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.5.0
./bin/end-to-end-pangolin-gerbil-companion-update-v1.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.11
./bin/apply-traefik-hop.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.11
./bin/verify-traefik-version.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.11
./bin/end-to-end-pangolin-traefik-companion-update-v1.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
```

Versioned helper examples above reflect the current known live baseline, not a future upgrade plan.

## CrowdSec 403 Triage

If a user reports a sudden `403` on Pangolin or a Pangolin-protected site, use the CrowdSec helper before assuming it is a Pangolin login problem:

```bash
./bin/diagnose-crowdsec-403.sh <ssh-target> <stack-path> <public-ip>
```

Reference:

- [docs/CROWDSEC_403_FALSE_POSITIVE_HELPER.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/CROWDSEC_403_FALSE_POSITIVE_HELPER.md)

## Legacy Material

The repo still contains older runbooks and lab notes. They are useful context, but they are not the worker contract for this bounded workflow.
