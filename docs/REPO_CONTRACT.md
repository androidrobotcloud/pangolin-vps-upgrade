# Repo Contract

This repo is minimum worker-operable for bounded workflows:

- `environment-status-scan-v1`

- `pangolin-readonly-audit-v1`
- `pangolin-upgrade-readiness-audit-v1`
- `pangolin-staged-upgrade-v1`
- `pangolin-gerbil-companion-update-v1`
- `pangolin-traefik-companion-update-v1`

## Required Surface Present For This Workflow

- `README.md`
- `docs/ENVIRONMENTS.md`
- `docs/handoffs/environment-status-scan-v1.md`
- `specs/environments/`
- `bin/environment-status-scan.sh`
- `docs/MASTER_OPERATING_POLICY.md`
- `docs/REPO_CONTRACT.md`
- `docs/HANDOFF_TEMPLATE.md`
- `docs/WORKER_PROMPT.md`
- `docs/runtime/CURRENT_STATE.md`
- `docs/runtime/vm890.md`
- `docs/handoffs/pangolin-readonly-audit-v1.md`
- `docs/handoffs/pangolin-upgrade-readiness-audit-v1.md`
- `docs/handoffs/pangolin-staged-upgrade-v1.md`
- `docs/handoffs/pangolin-gerbil-companion-update-v1.md`
- `docs/handoffs/pangolin-traefik-companion-update-v1.md`
- `docs/reports/`
- `bin/`
- `env/`
- `specs/`

## Workflow Definition

### Workflow IDs

- `environment-status-scan-v1`

- `pangolin-readonly-audit-v1`
- `pangolin-upgrade-readiness-audit-v1`
- `pangolin-staged-upgrade-v1`
- `pangolin-gerbil-companion-update-v1`
- `pangolin-traefik-companion-update-v1`

### Work Classes

- `environment-status-scan-v1`: `read-only infrastructure / documentation mutation`

- `pangolin-readonly-audit-v1`: `read-only`
- `pangolin-upgrade-readiness-audit-v1`: `read-only`
- `pangolin-staged-upgrade-v1`: `mutating`
- `pangolin-gerbil-companion-update-v1`: `mutating`
- `pangolin-traefik-companion-update-v1`: `mutating`

### Target Environment

`vm890`

### Goals

- `environment-status-scan-v1`: scan one canonical environment, compare verified runtime evidence with its runtime profile, prior scan, and `docs/ENVIRONMENTS.md`, then update permitted documentation without remediating infrastructure

- `pangolin-readonly-audit-v1`: produce a safe, repeatable runtime audit of the live Pangolin stack on `vm890`
- `pangolin-upgrade-readiness-audit-v1`: produce a safe, repeatable, read-only upgrade-readiness assessment for the live Pangolin stack on `vm890` using live runtime facts plus official upstream release data
- `pangolin-staged-upgrade-v1`: perform a staged, backup-backed Pangolin-only upgrade on `vm890` using explicit version hops and verification gates, without changing companion services
- `pangolin-gerbil-companion-update-v1`: perform a staged, backup-backed Gerbil-only companion upgrade on `vm890` using explicit version hops and verification gates, without changing Pangolin, Traefik, CrowdSec, or unrelated containers
- `pangolin-traefik-companion-update-v1`: perform a staged, backup-backed Traefik-only companion upgrade on `vm890` using explicit version hops and verification gates, without changing Pangolin, Gerbil, CrowdSec, Badger config, or unrelated containers

## Helper Path

- `bin/environment-status-scan.sh`

- `bin/check-vm890-profile.sh`
- `bin/verify-vm890-runtime.sh`
- `bin/end-to-end-pangolin-readonly-audit-v1.sh`
- `bin/verify-pangolin-upgrade-readiness.sh`
- `bin/end-to-end-pangolin-upgrade-readiness-audit-v1.sh`
- `bin/create-pangolin-backup.sh`
- `bin/create-stack-backup.sh`
- `bin/apply-pangolin-hop.sh`
- `bin/verify-pangolin-version.sh`
- `bin/end-to-end-pangolin-staged-upgrade-v1.sh`
- `bin/apply-gerbil-hop.sh`
- `bin/verify-gerbil-version.sh`
- `bin/end-to-end-pangolin-gerbil-companion-update-v1.sh`
- `bin/apply-traefik-hop.sh`
- `bin/verify-traefik-version.sh`
- `bin/end-to-end-pangolin-traefik-companion-update-v1.sh`

## Input Spec

- `specs/environments/<environment>.conf`

- `specs/pangolin-readonly-audit-v1.vm890.conf`
- `specs/pangolin-upgrade-readiness-audit-v1.vm890.conf`
- `specs/pangolin-staged-upgrade-v1.vm890.conf`
- `specs/pangolin-gerbil-companion-update-v1.vm890.conf`
- `specs/pangolin-traefik-companion-update-v1.vm890.conf`

## Allowed Edits For Workers

Workers using this workflow may edit only:

- `docs/reports/*`

Workers must not edit:

- `bin/*`
- `docs/runtime/*`
- `docs/handoffs/*`
- legacy runbooks
- remote host files

## Approved Secret Source

- operator SSH access via `~/.ssh/config` or equivalent SSH agent-backed credentials for `hustler2025@vm890`

No repo secret file is required for this workflow.

## Acceptance Model

Success requires:

- profile check passes
- internal Pangolin health returns healthy
- canonical dashboard HTTPS check returns success
- final report is written in the standard format

For `pangolin-upgrade-readiness-audit-v1`, success also requires:

- official upstream release facts are gathered from primary sources
- the report states current runtime versus current-line latest and overall latest
- the report includes a safe read-only proposed version path and explicit stop at execution

For `pangolin-staged-upgrade-v1`, success also requires:

- a backup tarball is created before each Pangolin hop
- only the Pangolin image tag changes
- unrelated containers on the host are untouched
- each hop passes structural verification and runtime verification before the next hop
- the final report includes the executed hop sequence and backup filenames

For `pangolin-gerbil-companion-update-v1`, success also requires:

- a backup tarball is created before each Gerbil hop
- only the Gerbil image tag changes
- Pangolin, Traefik, CrowdSec, and unrelated containers remain present after each hop
- each hop passes structural verification and runtime verification before the next hop
- the final report includes the executed hop sequence and backup filenames

For `pangolin-traefik-companion-update-v1`, success also requires:

- a backup tarball is created before each Traefik hop
- only the Traefik image tag changes
- Pangolin, Gerbil, CrowdSec, and unrelated containers remain present after each hop
- each hop passes structural verification and runtime verification before the next hop
- the final report includes the executed hop sequence and backup filenames

## Environment Status Workflow Rule

`docs/ENVIRONMENTS.md` is mandatory input to environment-status work. A scan may update the selected runtime profile and a dated report. It may update `docs/ENVIRONMENTS.md` only when a verified standard environment field materially changes; a routine scan alone must not bump its Last updated date. Infrastructure remains read-only during this workflow. Any remediation is a separate authorised task. Environments whose spec uses `ADAPTER=manual` are deliberately not automated yet and must stop rather than guess.
