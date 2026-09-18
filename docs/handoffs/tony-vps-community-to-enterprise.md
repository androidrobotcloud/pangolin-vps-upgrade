# Worker Handoff

## Task ID

`tony-vps-community-to-enterprise-v1`

## Goal

Safely bring the Pangolin stack on `revelectronics@tony_vps` to the latest stable Community Edition first, then convert it to the matching Enterprise Edition at the same version, preserving rollback data before every mutating step.

## Work Class

- mutating

## Confidence

- medium

Reason:

The repo already contains reusable backup and staged Pangolin helper scripts, but the bounded worker contract was originally built for `vm890`. This task must first prove and document the live `tony_vps` runtime facts before reusing the same safe pattern.

## Source-Of-Truth Files

Read these first, in order:

1. `docs/MASTER_OPERATING_POLICY.md`
2. `docs/runtime/tony_vps.md`
3. `docs/runtime/CURRENT_STATE.md`
4. `README.md`
5. `docs/CROWDSEC_403_FALSE_POSITIVE_HELPER.md`
6. `docs/runtime/vm890.md`
7. `docs/handoffs/pangolin-readonly-audit-v1.md`
8. `docs/handoffs/pangolin-staged-upgrade-v1.md`

## Base Reference

- Repo: `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade`
- Branch: current working branch
- Environment: `tony_vps`
- Runtime profile: `docs/runtime/tony_vps.md`
- Canonical URL / entrypoint: `https://pangolin.pang.revelectronics.uk`
- Approved secret source: local SSH access for `revelectronics@tony_vps`
- Prior proven pattern: `vm890` Community and Enterprise staged work in this repo

## Verified Facts

- SSH target should be `revelectronics@tony_vps`
- stack path should be `/home/revelectronics/docker/pangolin`
- canonical dashboard should be `https://pangolin.pang.revelectronics.uk`
- the final process must preserve rollback tarballs before every mutating step
- do not stop or modify unrelated containers outside the Pangolin compose stack

## Allowed Paths

- `docs/runtime/tony_vps.md`
- `docs/reports/*`
- `specs/*tony_vps*`

## Forbidden Paths

- `docs/reports/*` historical reports for `vm890`
- `docs/runtime/vm890.md`
- `docs/runtime/CURRENT_STATE.md`
- remote files outside the Pangolin stack path

## Inputs / Specs

Create host-specific specs as part of the task. Suggested names:

- `specs/pangolin-readonly-audit-v1.tony_vps.conf`
- `specs/pangolin-upgrade-readiness-audit-v1.tony_vps.conf`
- `specs/pangolin-staged-upgrade-v1.tony_vps.conf`
- `specs/pangolin-enterprise-conversion-v1.tony_vps.conf`

## Required Helper Commands

Use repo helpers where they fit. The filenames still say `vm890`, but they are spec-driven:

```bash
./bin/check-vm890-profile.sh <tony-spec>
./bin/verify-vm890-runtime.sh <tony-spec>
./bin/create-pangolin-backup.sh <tony-spec> <target-version>
./bin/create-stack-backup.sh <tony-spec> <target-label>
./bin/apply-pangolin-hop.sh <tony-spec> <target-version>
./bin/verify-pangolin-version.sh <tony-spec> <target-version>
```

## Optional Read-Only Confidence Check

```bash
ssh revelectronics@tony_vps 'hostname && cd /home/revelectronics/docker/pangolin && docker compose ps && docker compose images'
```

## Execution Plan

1. Bootstrap live facts read-only.
2. Create `tony_vps` runtime/spec files from live facts.
3. Run a read-only audit and a read-only upgrade-readiness check.
4. Determine the latest stable Community Pangolin version from primary sources on the day of execution.
5. If the host is behind, perform staged Community Pangolin hops only, with a tar backup before each hop.
6. Validate health after each Community hop.
7. Once Community is current, take another backup and perform a same-version edition swap:
   - from `fosrl/pangolin:<current-community-version>`
   - to `fosrl/pangolin:ee-<same-version>`
8. Validate runtime on the `ee` image before license activation.
9. Activate the Enterprise key in the Pangolin UI at `/admin/license`.
10. Re-verify internal health, public HTTPS, compose status, and short logs.

## Acceptance Criteria

- `tony_vps` runtime profile is verified and updated from live facts
- host-specific specs exist and pass read-only checks before mutation
- every mutating step has a corresponding rollback tarball
- Pangolin reaches the latest stable Community version first
- Pangolin then reaches the matching `ee-<same-version>` image
- internal Pangolin health is healthy after each stage
- canonical dashboard HTTPS returns success after each stage
- unrelated containers outside the Pangolin stack remain untouched
- final report is written under `docs/reports/`

## Stop Conditions

- SSH to `revelectronics@tony_vps` fails
- hostname or stack path does not match the bootstrap runtime profile
- compose service layout differs materially from expected Pangolin layout
- a helper script cannot be reused safely with the host-specific spec
- a backup tarball cannot be created
- any Pangolin hop fails verification
- any edition swap to `ee-<same-version>` fails verification
- a license key is missing when the thread reaches the Enterprise activation step

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
