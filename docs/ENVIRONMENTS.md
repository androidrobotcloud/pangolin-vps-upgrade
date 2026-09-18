# Environments

> Canonical environment baseline for this repository.
>
> Last updated: 2026-09-18
>
> Purpose: give operators and agents a single, current map of the distinct Pangolin environments, their rationale, their major components, and the intended relationship between them. Read this before environment-specific runtime profiles, handoffs, or mutation work.

## Naming and safety invariant

The canonical environment identifiers are:

- `vm890`
- `vm890_backup`
- `incus_lan`
- `tony_vps`
- `tony_garage`

These are separate environments even where they currently share infrastructure or derive from one another.

**Never infer that two environments are the same merely because they currently share a Pangolin control plane, configuration lineage, host, or connectivity. A task targeting one environment must not mutate another unless the owner explicitly authorises a cross-environment operation.**

Where this file and older historical notes disagree about environment identity or intended role, this file records the current intent. Live runtime facts still require read-only verification before mutation.

## Owner environments

### `vm890` — primary VPS environment

**Rationale:** The owner's existing public/cloud Pangolin environment and independently managed production VPS stack.

**Known components / role:**
- VPS host: `vm890`
- Pangolin Enterprise
- Gerbil
- Traefik
- CrowdSec
- existing public Pangolin resources and sites

**Current known runtime baseline:** See `docs/runtime/CURRENT_STATE.md` and `docs/runtime/vm890.md`.

**Relationship:** This is the source environment from which the offline/local clone was derived, but remains an independent environment.

### `vm890_backup` — local offline clone of VM890

**Rationale:** A local Incus-contained clone of the VM890 Pangolin environment for rollback/recovery, offline inspection, and safe testing without changing the live VPS.

**Known components / role:**
- runs locally under Incus
- derived from VM890
- intended to reproduce the VM890 stack sufficiently for offline/local recovery and testing

**Current known runtime baseline:** See `docs/runtime/vm890-backup.md` and `VM890_OFFLINE_CLONE_RUNBOOK.md`.

**Relationship:** Derived from `vm890`, but it is not `vm890` and must not be treated as the live VPS.

### `incus_lan` — local-only Pangolin Enterprise environment

**Rationale:** A smaller, separate local-only Pangolin Enterprise stack running under Incus. It exists to provide/test a LAN-local Pangolin architecture independently of the full VM890 clone.

**Known components / role:**
- Incus instance currently known as `pangolin-lan`
- Pangolin Enterprise
- Docker nested inside Incus
- local/LAN-oriented Pangolin stack
- staged configuration under `staging/pangolin-lan/`

**Containment invariant:** In this architecture, Incus is the workload containment boundary. Docker, Pangolin configuration, databases and persistent workload state are kept within the Incus instance/root storage unless explicitly documented otherwise. Do not re-investigate nested Docker storage merely to prove snapshot coverage; only investigate when there is concrete evidence of an Incus-level external disk/bind/custom volume.

**Current known runtime baseline:** The latest verified operational evidence should be recorded in a dedicated runtime profile as this environment evolves.

**Relationship:** Independent of both `vm890` and `vm890_backup`.

## Tony environments

### `tony_vps` — Tony's existing VPS Pangolin environment

**Rationale:** Tony's existing public/cloud Pangolin environment. It remains a permanent, independently managed environment.

**Known components / role:**
- host alias: `tony_vps`
- Pangolin Enterprise
- Gerbil
- Traefik
- CrowdSec
- public dashboard/domain and existing remote connectivity

**Current known runtime baseline:** See `docs/runtime/tony_vps.md`.

**Relationship:** At the time of this baseline, Tony Garage resources still use/share the Pangolin infrastructure on `tony_vps`. That shared dependency is transitional. It does **not** make Tony Garage and Tony VPS one environment.

### `tony_garage` — Tony's work / bus-garage environment

**Rationale:** Tony's on-premises work environment. The target architecture is local-first so garage applications remain usable on the garage LAN even when the 5G WAN connection is unavailable.

**Known components / intended role:**
- TP-Link Archer NX500 v2.0: 5G WAN, Wi-Fi, routing and DHCP
- UGREEN NAS: local compute/storage host
- Incus: workload isolation/containment
- existing application Incus instances, including Hermes and ramp workloads
- dedicated infrastructure/ingress Incus instance
- Technitium DNS as local authoritative DNS
- local Pangolin Enterprise control/ingress plane
- Newt/site connectivity where required by the final design

**Target architecture:** Tony Garage receives its own local Pangolin infrastructure. Local DNS should resolve garage-local services to the local ingress path. The explicit acceptance criterion is that authorised clients connected to the garage LAN can resolve and reach required local applications when the 5G WAN is physically unavailable.

**Current transition state:** Tony Garage currently depends on the Pangolin instance on `tony_vps`. The project will separate that dependency by introducing the garage-local Pangolin environment while preserving `tony_vps` as its own independently managed environment.

**Relationship:** `tony_garage` and `tony_vps` are separate operational environments. Migration work may deliberately touch both, but only when the owner explicitly authorises a cross-environment migration step.

## Environment selection rule

Before any mutating operation, state the target canonical environment identifier and verify the corresponding runtime facts. If a task says only "Tony", "local Pangolin", "the VPS", or another ambiguous label, resolve it against this file and the active handoff before making changes.

Historical reports remain valid evidence of what happened at the time, but they must not override this environment map or newer verified runtime state.

## Maintenance rule

Update this file whenever:
- an environment is added, retired, renamed, or changes purpose;
- an important component moves between environments;
- a transitional dependency is removed or introduced;
- the intended architecture changes.

For each update, change the **Last updated** date and update the relevant runtime profile/handoff where concrete runtime facts also changed.
