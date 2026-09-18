# Worker Handoff

## Task ID

`pangolin-traefik-companion-update-v1`

## Goal

Perform the deterministic, staged Traefik-only companion upgrade on the live `vm890` stack using pre-defined hops, backup tarballs before each hop, and verification after each hop.

## Work Class

`mutating`

## Confidence

`medium`

Reason:

The host, stack path, helper path, and current versions were re-verified on `2026-06-17`, but this workflow mutates a live public-facing reverse proxy and crosses from Traefik `v3.6` to `v3.7`.

## Owner Approval

Explicit owner approval for planner execution in this thread was given on `2026-06-17` with: `Proceed`

Workers must not run this workflow unless the operator explicitly selects this handoff.

## Source-Of-Truth Files

Read these first, in order:

1. `docs/MASTER_OPERATING_POLICY.md`
2. `docs/REPO_CONTRACT.md`
3. `docs/runtime/vm890.md`
4. `README.md`
5. `specs/pangolin-traefik-companion-update-v1.vm890.conf`
6. `docs/reports/2026-06-17-pangolin-upgrade-readiness-audit-v1-post-gerbil.md`

## Base Reference

- Repo: `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade`
- Environment: `vm890`
- Runtime profile: `docs/runtime/vm890.md`
- Canonical URL / entrypoint: `https://pangolin.pang.androidrobot.cloud`
- Approved secret source: local SSH access for `hustler2025@vm890`

## Verified Facts

- The compose stack path is `/home/hustler2025/docker/pangolin-vps`
- The live Pangolin version before this workflow is `1.19.2`
- The live Gerbil version before this workflow is `1.4.2`
- The live Traefik version before this workflow is `v3.6.16`
- The staged Traefik hop path is `v3.6.21 -> v3.7.5`
- Pangolin, Gerbil, CrowdSec, and Badger plugin config are intentionally not version-bumped by this workflow
- The canonical dashboard URL currently returns `HTTP/2 200`
- The stack does not currently show `BasicAuth` or `StripPrefix` middleware use in the checked Traefik config files

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

- `specs/pangolin-traefik-companion-update-v1.vm890.conf`

## Required Helper Commands

Run these from repo root:

```bash
./bin/check-vm890-profile.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.6.21
./bin/apply-traefik-hop.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.6.21
./bin/verify-traefik-version.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.6.21
./bin/create-stack-backup.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.5
./bin/apply-traefik-hop.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.5
./bin/verify-traefik-version.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.5
./bin/end-to-end-pangolin-traefik-companion-update-v1.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
```

## Acceptance Criteria

Success requires all of:

- profile check passes before mutation
- a backup tarball is created before each hop
- Traefik reaches `v3.6.21`, then `v3.7.5`
- internal Pangolin health returns healthy after each hop
- canonical dashboard HTTPS returns success after each hop
- Pangolin, Gerbil, CrowdSec, and unrelated containers remain present after each hop
- final report is written under `docs/reports/`
- final report includes backup filenames and executed hop sequence

## Stop Conditions

Stop immediately if:

- SSH to `hustler2025@vm890` fails
- the hostname is not `vm890`
- the stack path does not exist
- the current Traefik image is not the expected pre-hop value
- backup creation fails
- `docker compose down`, `pull`, or `up -d` fails
- Pangolin internal health fails after a hop
- canonical dashboard HTTPS fails after a hop
- unrelated containers stop unexpectedly
- the Traefik logs show a startup failure or config parsing failure after a hop
- any step would require upgrading Pangolin, Gerbil, Badger config, or other companion services to continue

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

This workflow upgrades Traefik only. It intentionally treats the `v3.6 -> v3.7` move as a separate companion task with backups at each hop.
