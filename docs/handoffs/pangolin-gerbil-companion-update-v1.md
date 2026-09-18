# Worker Handoff

## Task ID

`pangolin-gerbil-companion-update-v1`

## Goal

Perform the deterministic, staged Gerbil-only companion upgrade on the live `vm890` stack using pre-defined hops, backup tarballs before each hop, and verification after each hop.

## Work Class

`mutating`

## Confidence

`medium`

Reason:

The host, stack path, helper path, and current versions were re-verified on `2026-06-17`, but this workflow mutates a live system and restarts the Pangolin compose stack as part of the Gerbil companion update.

## Owner Approval

Explicit owner approval for planner execution in this thread was given on `2026-06-17` with: `Proceed`

Workers must not run this workflow unless the operator explicitly selects this handoff.

## Source-Of-Truth Files

Read these first, in order:

1. `docs/MASTER_OPERATING_POLICY.md`
2. `docs/REPO_CONTRACT.md`
3. `docs/runtime/vm890.md`
4. `README.md`
5. `specs/pangolin-gerbil-companion-update-v1.vm890.conf`
6. `docs/reports/2026-06-17-pangolin-upgrade-readiness-audit-v1-run.md`

## Base Reference

- Repo: `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade`
- Environment: `vm890`
- Runtime profile: `docs/runtime/vm890.md`
- Canonical URL / entrypoint: `https://pangolin.pang.androidrobot.cloud`
- Approved secret source: local SSH access for `hustler2025@vm890`

## Verified Facts

- The compose stack path is `/home/hustler2025/docker/pangolin-vps`
- The live Pangolin version before this workflow is `1.19.2`
- The live Gerbil version before this workflow is `1.4.0`
- The staged Gerbil hop path is `1.4.1 -> 1.4.2`
- Pangolin, Traefik, CrowdSec, and Badger are intentionally not version-bumped by this workflow
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

- `specs/pangolin-gerbil-companion-update-v1.vm890.conf`

## Required Helper Commands

Run these from repo root:

```bash
./bin/check-vm890-profile.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.1
./bin/apply-gerbil-hop.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.1
./bin/verify-gerbil-version.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.1
./bin/create-stack-backup.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.2
./bin/apply-gerbil-hop.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.2
./bin/verify-gerbil-version.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.2
./bin/end-to-end-pangolin-gerbil-companion-update-v1.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
```

## Acceptance Criteria

Success requires all of:

- profile check passes before mutation
- a backup tarball is created before each hop
- Gerbil reaches `1.4.1`, then `1.4.2`
- internal Pangolin health returns healthy after each hop
- canonical dashboard HTTPS returns success after each hop
- Pangolin, Traefik, CrowdSec, and unrelated containers remain present after each hop
- final report is written under `docs/reports/`
- final report includes backup filenames and executed hop sequence

## Stop Conditions

Stop immediately if:

- SSH to `hustler2025@vm890` fails
- the hostname is not `vm890`
- the stack path does not exist
- the current Gerbil image is not the expected pre-hop value
- backup creation fails
- `docker compose down`, `pull`, or `up -d` fails
- Pangolin internal health fails after a hop
- canonical dashboard HTTPS fails after a hop
- unrelated containers stop unexpectedly
- any step would require upgrading Pangolin, Traefik, Badger, or other companion services to continue

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

This workflow upgrades Gerbil only. Traefik current-line patching should be handled as a separate workflow.
