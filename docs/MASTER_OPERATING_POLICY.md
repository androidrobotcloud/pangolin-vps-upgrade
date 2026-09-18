# Master Operating Policy

This repo follows the AI-operable repo pattern for one bounded workflow.

The goal is deterministic planner-to-worker execution with low token burn, verified runtime facts, and explicit stop conditions.

## Roles

### Owner / Operator

The owner decides:

- which host and environment are in scope
- whether live systems may be changed
- whether destructive actions are allowed
- whether secrets, credentials, or endpoints may be altered

Agents must not silently make owner-level decisions.

### Planner

The planner must:

- verify runtime facts before documenting them
- identify stale assumptions
- create or update the minimum helper path
- create or update runtime and handoff docs
- prove the workflow before delegating it

### Worker

The worker must:

- read only the handoff and named source-of-truth files
- use helper scripts before ad hoc commands
- stop on mismatch
- report evidence in the standard format

## Source-Of-Truth Priority

When sources disagree, use this order:

1. live read-only verification
2. `docs/runtime/*.md`
3. `env/*`
4. `bin/*`
5. repo contract docs
6. active handoff
7. old reports and legacy notes
8. model memory

Model memory is never evidence.

## Work Classes

### Read-Only

Examples:

- SSH inspection
- Docker Compose inspection
- health checks
- report generation

### Mutating

Examples:

- config changes
- upgrades
- restarts
- backup creation

### Destructive

Examples:

- deleting data
- resetting databases
- replacing canonical routes
- removing certificates or persistent state

Destructive work requires explicit owner approval.

## Secrets Policy

- Do not commit real secrets.
- Do not print secrets in reports.
- Approved secret sources must be named, not exposed.
- If a required secret source is missing, stop.

## Script-First Rule

If a curated helper exists, use it before manual commands.

## Stop Conditions

Workers must stop when:

- the runtime profile check fails
- the target host, stack path, or canonical URL differs from the handoff
- a required helper is missing
- SSH access is unavailable
- command output contradicts verified facts
- runtime acceptance checks fail
- the task would require mutation or destructive action

## Success Rule

Success requires real runtime evidence, not just structure.
