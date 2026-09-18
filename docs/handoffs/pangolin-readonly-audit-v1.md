# Worker Handoff

## Task ID

`pangolin-readonly-audit-v1`

## Goal

Run the deterministic read-only audit for the live Pangolin stack on `vm890` and write a report under `docs/reports/`.

## Work Class

`read-only`

## Confidence

`high`

Reason:

The target host, stack path, canonical URL, helper path, and acceptance checks were re-verified by the planner on `2026-06-17`.

## Source-Of-Truth Files

Read these first, in order:

1. `docs/MASTER_OPERATING_POLICY.md`
2. `docs/REPO_CONTRACT.md`
3. `docs/runtime/vm890.md`
4. `README.md`
5. `specs/pangolin-readonly-audit-v1.vm890.conf`

## Base Reference

- Repo: `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade`
- Branch: current local branch
- Environment: `vm890`
- Runtime profile: `docs/runtime/vm890.md`
- Canonical URL / entrypoint: `https://pangolin.pang.androidrobot.cloud`
- Approved secret source: local SSH access for `hustler2025@vm890`
- Prior proven run: `docs/reports/2026-06-17-pangolin-readonly-audit-v1-planner-proof.md`

## Verified Facts

- The live host is `vm890`
- The compose stack path is `/home/hustler2025/docker/pangolin-vps`
- The compose-managed services are `pangolin`, `gerbil`, `traefik`, and `crowdsec`
- The canonical dashboard URL currently returns `HTTP/2 200`
- Pangolin internal health currently returns `{"message":"Healthy"}`

## Allowed Paths

The worker may edit only:

- `docs/reports/*`

## Forbidden Paths

The worker must not edit:

- `bin/*`
- `docs/runtime/*`
- `docs/handoffs/*`
- `PANGOLIN_INCREMENTAL_UPGRADE_RUNBOOK.md`
- `PANGOLIN_UPGRADE_CHECKLIST.md`
- any remote host file

## Inputs / Specs

Use this exact input:

- `specs/pangolin-readonly-audit-v1.vm890.conf`

## Required Helper Commands

Run these from repo root:

```bash
./bin/check-vm890-profile.sh specs/pangolin-readonly-audit-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-readonly-audit-v1.vm890.conf
./bin/end-to-end-pangolin-readonly-audit-v1.sh specs/pangolin-readonly-audit-v1.vm890.conf
```

## Optional Read-Only Confidence Check

If any helper output looks stale or contradictory, rerun:

```bash
./bin/check-vm890-profile.sh specs/pangolin-readonly-audit-v1.vm890.conf
```

Proceed only if it matches the runtime profile.

## Acceptance Criteria

Success requires all of:

- profile check passes
- internal Pangolin health returns healthy
- canonical dashboard HTTPS check returns success
- a final report is written under `docs/reports/`
- the report uses the standard final report format

## Stop Conditions

Stop immediately if:

- SSH to `hustler2025@vm890` fails
- the hostname is not `vm890`
- the stack path does not exist
- required containers or compose services differ from the runtime profile
- the canonical dashboard URL check fails
- the Pangolin internal health check fails
- any step would require a restart, upgrade, backup, or config change
- the requested work expands beyond `docs/reports/*`

## Rollback / Pause Rules

- Rollback available: not applicable for this read-only workflow
- Pause and report before: any action that would mutate the repo outside `docs/reports/*` or touch the remote host state

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

This workflow is for runtime truth only. Do not extend it into upgrade planning or execution.
