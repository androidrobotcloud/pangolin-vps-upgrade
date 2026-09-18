# Worker Handoff

## Task ID

`pangolin-staged-upgrade-v1`

## Goal

Perform the deterministic, staged Pangolin-only upgrade on the live `vm890` stack using pre-defined hops, backup tarballs before each hop, and verification after each hop.

## Work Class

`mutating`

## Confidence

`medium`

Reason:

The host, stack path, helper path, and current versions were re-verified on `2026-06-17`, but this workflow mutates a live system and relies on current upstream release facts that may drift.

## Owner Approval

Explicit owner approval for planner execution in this thread was given on `2026-06-17` with: `Proceed`

Workers must not run this workflow unless the operator explicitly selects this handoff.

## Source-Of-Truth Files

Read these first, in order:

1. `docs/MASTER_OPERATING_POLICY.md`
2. `docs/REPO_CONTRACT.md`
3. `docs/runtime/vm890.md`
4. `README.md`
5. `specs/pangolin-staged-upgrade-v1.vm890.conf`
6. `PANGOLIN_INCREMENTAL_UPGRADE_RUNBOOK.md`
7. `docs/reports/2026-06-17-pangolin-upgrade-readiness-audit-v1-planner-proof.md`

## Base Reference

- Repo: `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade`
- Environment: `vm890`
- Runtime profile: `docs/runtime/vm890.md`
- Canonical URL / entrypoint: `https://pangolin.pang.androidrobot.cloud`
- Approved secret source: local SSH access for `hustler2025@vm890`
- Prior proven run: `docs/reports/2026-06-17-pangolin-upgrade-readiness-audit-v1-planner-proof.md`

## Verified Facts

- The compose stack path is `/home/hustler2025/docker/pangolin-vps`
- The live Pangolin version before this workflow is `1.18.3`
- The staged Pangolin hop path is `1.18.4 -> 1.19.2`
- Gerbil, Traefik, CrowdSec, and Badger are intentionally not upgraded by this workflow
- The canonical dashboard URL currently returns `HTTP/2 200`

## Allowed Paths

The worker may edit only:

- `docs/reports/*`

The worker may mutate only this remote stack:

- `/home/hustler2025/docker/pangolin-vps`
- `/home/hustler2025/docker/pangolin-vps-backups`

## Forbidden Paths

The worker must not edit:

- `bin/*`
- `docs/runtime/*`
- `docs/handoffs/*`
- `PANGOLIN_INCREMENTAL_UPGRADE_RUNBOOK.md`
- `PANGOLIN_UPGRADE_CHECKLIST.md`
- unrelated remote host files
- unrelated remote containers

## Inputs / Specs

Use this exact input:

- `specs/pangolin-staged-upgrade-v1.vm890.conf`

## Required Helper Commands

Run these from repo root:

```bash
./bin/check-vm890-profile.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.18.4
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.18.4
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.18.4
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.19.2
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.19.2
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.19.2
./bin/end-to-end-pangolin-staged-upgrade-v1.sh specs/pangolin-staged-upgrade-v1.vm890.conf
```

## Acceptance Criteria

Success requires all of:

- profile check passes before mutation
- a backup tarball is created before each hop
- Pangolin reaches `1.18.4`, then `1.19.2`
- internal Pangolin health returns healthy after each hop
- canonical dashboard HTTPS check returns success after each hop
- unrelated containers remain running
- final report is written under `docs/reports/`
- final report includes backup filenames and executed hop sequence

## Stop Conditions

Stop immediately if:

- SSH to `hustler2025@vm890` fails
- the hostname is not `vm890`
- the stack path does not exist
- the current Pangolin image is not the expected pre-hop value
- backup creation fails
- `docker compose down`, `pull`, or `up -d` fails
- Pangolin internal health fails after a hop
- canonical dashboard HTTPS fails after a hop
- unrelated containers stop unexpectedly
- any step would require upgrading Gerbil, Traefik, Badger, or other companion services to continue

## Rollback / Pause Rules

- Rollback available: yes, from the per-hop backup tarballs
- Pause and report before: any manual deviation from the helper path
- Do not attempt an automatic rollback unless the operator explicitly asks for it

## Final Report Format

```text
Task:
Result:
Confidence:
Work class:
Files changed:
Commands run:
Evidence:
Acceptance criteria:
Problems found:
Problems fixed:
Stop conditions hit:
Remaining risks:
Next recommended task:
```

## Notes

This workflow upgrades Pangolin only. Companion-service upgrades are separate workflows.
