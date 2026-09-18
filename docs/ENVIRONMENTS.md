# Environments

> Canonical environment baseline for this repository.
>
> Last updated: 2026-09-18
>
> Purpose: provide operators and agents with one current, standardised map of every managed Pangolin environment: ownership, management authority, rationale, components, state, relationships, and runtime source of truth.

## Standard environment record

Every environment in this file MUST use the same fields:

- **Environment ID** — canonical machine-readable identifier used in plans, handoffs and reports.
- **Display name** — human-readable name.
- **Owner** — whose environment it is.
- **Managed by** — who has operational/admin authority to manage it.
- **Management authority** — whether the named manager is authorised to administer and change the environment without seeking separate owner approval for routine authorised work.
- **Purpose / rationale** — why the environment exists.
- **Location / platform** — where/how it runs.
- **Major components** — principal infrastructure/services.
- **Current state / intent** — current operational role or transition state.
- **Relationships** — dependencies or lineage involving other environments.
- **Runtime source of truth** — the runtime profile/runbook that contains concrete operational facts.
- **Last updated** — date this environment record was last materially updated.

Ownership and management authority are deliberately separate concepts. **Owner does not mean operator.** An environment may belong to Tony while being fully administered on Tony's behalf by the repository operator.

## Authority and safety rules

The canonical environment identifiers are:

- `vm890`
- `vm890_backup`
- `incus_lan`
- `tony_vps`
- `tony_garage`

These are separate environments even where they share infrastructure, configuration lineage, or connectivity.

The repository operator is the authorised administrator/manager for all environments listed here. For `tony_vps` and `tony_garage`, the operator manages the environments **on Tony's behalf with full administrative authority**. Agents must not introduce an additional workflow requirement to obtain Tony's permission before routine or explicitly operator-authorised work. Existing repo mutation/destructive-work approval gates still apply to the operator: this statement establishes management authority; it does not waive safety controls.

**Never infer that two environments are the same merely because they currently share a Pangolin control plane, configuration lineage, host, or connectivity. A task targeting one environment must not mutate another unless the operator explicitly authorises a cross-environment operation.**

Where this file and older historical notes disagree about environment identity, ownership, management authority, or intended role, this file records the current intent. Live runtime facts still require read-only verification before mutation.

---

## Environment: `vm890`

- **Environment ID:** `vm890`
- **Display name:** VM890
- **Owner:** Repository operator
- **Managed by:** Repository operator
- **Management authority:** Direct owner/admin authority
- **Purpose / rationale:** Primary public/cloud Pangolin environment and independently managed production VPS stack.
- **Location / platform:** VPS host `vm890`
- **Major components:** Pangolin Enterprise; Gerbil; Traefik; CrowdSec; existing public Pangolin resources and sites.
- **Current state / intent:** Live independently managed VPS environment.
- **Relationships:** Source environment from which `vm890_backup` was derived. It remains independent from that clone and from `incus_lan`.
- **Runtime source of truth:** `docs/runtime/CURRENT_STATE.md` and `docs/runtime/vm890.md`
- **Last updated:** 2026-09-18

## Environment: `vm890_backup`

- **Environment ID:** `vm890_backup`
- **Display name:** VM890 local offline clone
- **Owner:** Repository operator
- **Managed by:** Repository operator
- **Management authority:** Direct owner/admin authority
- **Purpose / rationale:** Local clone of VM890 for rollback/recovery, offline inspection, and safe testing without changing the live VPS.
- **Location / platform:** Local Incus environment
- **Major components:** Incus-contained clone derived from VM890; nested Pangolin stack and supporting workload state.
- **Current state / intent:** Offline/local recovery and test environment. It is not the live VPS.
- **Relationships:** Derived from `vm890`, but operationally separate from it.
- **Runtime source of truth:** `docs/runtime/vm890-backup.md` and `VM890_OFFLINE_CLONE_RUNBOOK.md`
- **Last updated:** 2026-09-18

## Environment: `incus_lan`

- **Environment ID:** `incus_lan`
- **Display name:** Incus LAN
- **Owner:** Repository operator
- **Managed by:** Repository operator
- **Management authority:** Direct owner/admin authority
- **Purpose / rationale:** Smaller, separate local-only Pangolin Enterprise environment for LAN-local operation/testing independently of the full VM890 clone.
- **Location / platform:** Local Incus; instance currently known as `pangolin-lan`
- **Major components:** Incus; nested Docker; Pangolin Enterprise; local/LAN-oriented Pangolin stack; staged configuration under `staging/pangolin-lan/`.
- **Current state / intent:** Independent local-only Pangolin Enterprise environment.
- **Relationships:** Independent of both `vm890` and `vm890_backup`.
- **Runtime source of truth:** Current staging/build documentation plus the latest verified operational evidence; a dedicated runtime profile should remain the canonical target as this environment evolves.
- **Last updated:** 2026-09-18

### Incus containment invariant

For Incus-based environments in this architecture, Incus is the workload containment boundary. Docker, Pangolin configuration, databases, and persistent workload state are kept within the Incus instance/root storage unless explicitly documented otherwise. Do not re-investigate nested Docker storage merely to prove Incus snapshot coverage. Only investigate snapshot-external state when there is concrete evidence of an Incus-level external disk device, host bind mount, custom external volume, or other persistent state outside the instance.

## Environment: `tony_vps`

- **Environment ID:** `tony_vps`
- **Display name:** Tony VPS
- **Owner:** Tony
- **Managed by:** Repository operator, on Tony's behalf
- **Management authority:** Full operational/admin authority. Do not require separate permission from Tony before work that the repository operator has authorised. Repository safety/approval gates still apply.
- **Purpose / rationale:** Tony's existing public/cloud Pangolin environment. It remains a permanent, independently managed environment.
- **Location / platform:** VPS host alias `tony_vps`
- **Major components:** Pangolin Enterprise; Gerbil; Traefik; CrowdSec; public dashboard/domain; existing remote connectivity.
- **Current state / intent:** Live Tony VPS environment. At this baseline it also provides the Pangolin infrastructure currently used by Tony Garage resources.
- **Relationships:** Currently shared by/dependent upon from `tony_garage` for Pangolin connectivity. That dependency is transitional and does not merge the two environment identities.
- **Runtime source of truth:** `docs/runtime/tony_vps.md`
- **Last updated:** 2026-09-18

## Environment: `tony_garage`

- **Environment ID:** `tony_garage`
- **Display name:** Tony Garage
- **Owner:** Tony
- **Managed by:** Repository operator, on Tony's behalf
- **Management authority:** Full operational/admin authority. Do not require separate permission from Tony before work that the repository operator has authorised. Repository safety/approval gates still apply.
- **Purpose / rationale:** Tony's on-premises work/bus-garage environment. Target architecture is local-first so required garage applications remain usable on the garage LAN when the 5G WAN is unavailable.
- **Location / platform:** Garage LAN; TP-Link Archer NX500 v2.0; UGREEN NAS; Incus
- **Major components:** NX500 for 5G WAN/Wi-Fi/routing/DHCP; UGREEN NAS; Incus workload isolation; existing Hermes/ramp application instances; planned dedicated infrastructure/ingress Incus instance; Technitium authoritative local DNS; local Pangolin Enterprise; Newt/site connectivity where required by the final design.
- **Current state / intent:** Garage workloads currently depend on the Pangolin instance in `tony_vps`. The target is a separate garage-local Pangolin control/ingress plane and local DNS path. Explicit acceptance criterion: authorised clients on the garage LAN can resolve and reach required local applications when the 5G WAN is physically unavailable.
- **Relationships:** Operationally distinct from `tony_vps`. The current shared Pangolin dependency is being separated. Cross-environment migration steps may deliberately touch both only when explicitly authorised by the repository operator.
- **Runtime source of truth:** A dedicated `docs/runtime/tony_garage.md` profile should be maintained as the garage build becomes concrete; until then this environment record plus verified live evidence defines intent.
- **Last updated:** 2026-09-18

## Environment selection rule

Before any mutating operation:

1. State the canonical **Environment ID**.
2. Read this environment record.
3. Read the named runtime source of truth.
4. Verify the concrete live facts required for the operation.

If a task says only "Tony", "local Pangolin", "the VPS", or another ambiguous label, resolve the intended environment against this file and the active handoff before making changes. Do not ask the operator to reconstruct information already recorded here unless current evidence genuinely conflicts with the baseline.

Historical reports remain valid evidence of what happened at the time, but they must not override this environment map or newer verified runtime state.

## Maintenance rule

Update this file whenever an environment is added, retired, renamed, changes owner/manager, changes purpose, gains or loses an important component, or changes a dependency/relationship.

Every environment entry must retain the standard fields above. Change both the document-level **Last updated** date and the affected environment's **Last updated** date when making a material change. Update the corresponding runtime profile/handoff when concrete runtime facts also change.
