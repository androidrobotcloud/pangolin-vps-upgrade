# Worker Handoff
## Task ID
`environment-status-scan-v1`
## Goal
Perform a deterministic read-only scan of one canonical environment, compare observed facts with the repo baseline and prior scan, then update repository documentation only where verified facts changed.
## Work Class
`read-only infrastructure / documentation mutation`
## Required Source-Of-Truth Order
1. `docs/MASTER_OPERATING_POLICY.md`
2. `docs/ENVIRONMENTS.md`
3. `docs/REPO_CONTRACT.md`
4. `docs/runtime/<environment>.md` when present
5. `specs/environments/<environment>.conf`
6. latest prior `docs/reports/*-environment-status-<environment>.md`
## Strict workflow
1. Run `./bin/environment-status-scan.sh <environment-id>`.
2. Prove the requested Environment ID/spec before remote inspection.
3. Collect read-only runtime evidence using the adapter declared in the spec.
4. Compare observed state with the runtime profile, ENVIRONMENTS.md intent, and latest prior scan.
5. Write a dated report.
6. Update the selected runtime profile only for verified operational facts.
7. Update ENVIRONMENTS.md only when a standard environment field materially changed; do not bump it merely because a scan ran.
8. Do not remediate infrastructure.
## Allowed repo edits
- `docs/reports/*-environment-status-*.md`
- selected `docs/runtime/<environment>.md`
- `docs/ENVIRONMENTS.md` only for verified material environment-definition changes
## Forbidden
Remote mutations, restarts, upgrades, config edits or cleanup; another environment's runtime profile; inferred ownership changes; accepting identity mismatch; secrets.
## Stop conditions
Stop if environment/spec is unknown, identity cannot be proved, required access/helper is unavailable, live evidence contradicts identity, or documentation updates cannot safely be distinguished from remediation.
