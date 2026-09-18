# Tony VPS Pangolin Audit Handoff

Use this document to start a fresh Codex session for auditing and, if appropriate, updating the Pangolin stack on:

- host: `tony_vps`
- SSH user: `revelectronics`
- login: `ssh revelectronics@tony_vps`

This handoff is designed so a fresh session can pick up the established workflow in this repo without rediscovering it.

## Current confirmed state

Last live session completed on `2026-05-23`.

- host: `tony_vps` (`vm895`)
- stack path: `/home/revelectronics/docker/pangolin`
- public FQDN: `pangolin.pang.revelectronics.uk`
- current Pangolin: `1.18.4`
- current Gerbil: `1.3.1`
- current Traefik: `v3.4.1`
- current CrowdSec: `latest`
- Pangolin internal health: healthy
- public dashboard HTTPS: `HTTP/2 200`

Known remaining issue:

- Traefik ACME is still attempting renewals for stale domains including `nextcloud.revelectronics.uk` and `revelectronics.uk`
- DNS-01 is the intended ACME mode for this host
- cleanup is tracked in [TO_DO.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/TO_DO.md)

Backups created during the live upgrade:

- `20260523-140249-pre-1.16.2.tar.gz`
- `20260523-140455-pre-1.17.1.tar.gz`
- `20260523-140709-pre-1.18.4.tar.gz`
- `20260523-151930-pre-gerbil-1.3.1.tar.gz`

## Objective

Audit the Pangolin Docker Compose stack on `revelectronics@tony_vps`, determine its current version/state, compare that to current upstream release guidance, and then plan and perform the safest appropriate update path using the runbooks and patterns already proven in this repo.

This is intended to be a live operational session, not just documentation review.

## Confirmed access

SSH access to the host has already been verified successfully:

```bash
ssh revelectronics@tony_vps 'printf CONNECTED'
```

Expected result:

```text
CONNECTED
```

## Working assumptions

- The target host runs a Pangolin stack in Docker Compose.
- The stack may include Pangolin, Gerbil, Traefik, and CrowdSec.
- The stack path is currently confirmed as `/home/revelectronics/docker/pangolin`.
- The session should follow the same cautious style used for previous Pangolin upgrades:
  - audit first
  - determine exact stack layout and versions
  - identify customizations
  - confirm the correct incremental upgrade path if needed
  - take backup tarballs before each change
  - do not stop unrelated containers

## Repo artifacts to use first

Read these before touching the host:

- [PANGOLIN_INCREMENTAL_UPGRADE_RUNBOOK.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/PANGOLIN_INCREMENTAL_UPGRADE_RUNBOOK.md)
- [PANGOLIN_UPGRADE_CHECKLIST.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/PANGOLIN_UPGRADE_CHECKLIST.md)

Secondary references in this repo:

- [PANGOLIN_LOCAL_DNS01_BUILD_AND_AUDIT.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/PANGOLIN_LOCAL_DNS01_BUILD_AND_AUDIT.md)
- [PANGOLIN_NESTED_INCUS_LAN_LAB_BUILD.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/PANGOLIN_NESTED_INCUS_LAN_LAB_BUILD.md)
- [VM890_OFFLINE_CLONE_RUNBOOK.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/VM890_OFFLINE_CLONE_RUNBOOK.md)
- [docs/CROWDSEC_403_FALSE_POSITIVE_HELPER.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/docs/CROWDSEC_403_FALSE_POSITIVE_HELPER.md)

These local-lab docs are not the main upgrade runbook, but they capture important Pangolin operational gotchas already discovered.

## Core operating rules

- Audit before editing anything.
- Use official Pangolin update guidance and release notes as the source of truth for upgrade sequencing.
- Use official Traefik releases if Traefik patching is considered.
- Take incremental backups before each version hop.
- Stop only the Pangolin Compose stack if a stack restart is required.
- Do not stop unrelated containers on the host.
- Prefer narrow-scope changes where possible.
- Treat root-owned files as likely and use Docker helper containers for backup or edits if needed.
- Validate after every hop before continuing.

## First commands to run

Start with a read-only audit to confirm the live stack path and current shape.

### 1. Confirm host basics and Docker

```bash
ssh revelectronics@tony_vps 'hostname && id && docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"'
```

### 2. Find likely Pangolin stack directories

```bash
ssh revelectronics@tony_vps 'find ~ -maxdepth 4 \( -name docker-compose.yml -o -name compose.yml \) 2>/dev/null | sort'
```

Known current result:

```text
/home/revelectronics/docker/pangolin/docker-compose.yml
```

### 3. Inspect the candidate stack

Once the stack path is identified:

```bash
ssh revelectronics@tony_vps 'cd /path/to/pangolin-stack && docker compose ps && docker compose images'
ssh revelectronics@tony_vps 'cd /path/to/pangolin-stack && sed -n "1,260p" docker-compose.yml'
ssh revelectronics@tony_vps 'cd /path/to/pangolin-stack && find config -maxdepth 3 -type f | sort | sed -n "1,240p"'
ssh revelectronics@tony_vps 'cd /path/to/pangolin-stack && du -sh config config/* 2>/dev/null | sort -h'
```

### 4. Health and logs

```bash
ssh revelectronics@tony_vps 'docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo'
ssh revelectronics@tony_vps 'docker logs --tail 120 pangolin'
ssh revelectronics@tony_vps 'docker logs --tail 120 gerbil'
ssh revelectronics@tony_vps 'docker logs --tail 120 traefik'
ssh revelectronics@tony_vps 'docker logs --tail 120 crowdsec'
```

If container names differ, adapt the commands after confirming the actual names from `docker ps`.

## What to extract from the audit

The fresh session should capture:

- stack path
- current Pangolin image tag
- current Gerbil image tag
- current Traefik image tag
- current CrowdSec image tag
- compose file structure
- config mount layout
- custom Traefik or CrowdSec behavior
- whether backup/log directories exist inside the stack tree
- whether files are root-owned
- whether the public dashboard FQDN can be identified from config

The last completed session already confirmed:

- stack path: `/home/revelectronics/docker/pangolin`
- current Pangolin image tag: `fosrl/pangolin:1.18.4`
- current Gerbil image tag: `fosrl/gerbil:1.3.1`
- current Traefik image tag: `traefik:v3.4.1`
- current CrowdSec image tag: `crowdsecurity/crowdsec:latest`
- public dashboard FQDN: `pangolin.pang.revelectronics.uk`
- related operational follow-up: ACME stale-domain cleanup

## Upgrade decision logic

After the audit:

1. Determine whether Pangolin is already current enough that no upgrade is needed.
2. If not current, use the official update method and release notes to decide the exact hop sequence.
3. If Pangolin is current but Traefik is stale, treat Traefik as a separate, optional patch task.
4. Keep Gerbil changes separate unless needed for compatibility or a deliberate companion update.

## Backup method to prefer

If the stack path is, for example, `/path/to/pangolin-stack`, use this pattern:

```bash
stamp=$(date +%Y%m%d-%H%M%S)
backup_name=${stamp}-pre-<TARGET>.tar.gz

docker run --rm \
  -v /path/to/pangolin-stack:/src:ro \
  -v /path/to/pangolin-backups:/backups \
  alpine:3.20 \
  sh -lc "cd /src && tar -czpf /backups/$backup_name docker-compose.yml config"
```

This is the preferred pattern because it has already proven safer with root-owned Pangolin files.

## Known Pangolin gotchas worth remembering

- Incremental upgrades matter across multiple minor versions.
- RBAC and identity-related changes matter across `1.17.x`.
- Health checks, status history, and network data migrations matter across `1.18.x`.
- Traefik can show brief startup failures during restarts even when the stack settles healthy.
- Pangolin health is usually most reliable from inside the container.
- Custom Traefik/CrowdSec tuning makes broad “upgrade everything at once” plans riskier.
- A sudden `403` can be a CrowdSec IP remediation rather than a Pangolin login/access problem. On this host, confirm that with `./bin/diagnose-crowdsec-403.sh revelectronics@tony_vps /home/revelectronics/docker/pangolin <public-ip>`.

## CrowdSec false-positive shortcut

If a trusted user suddenly gets `403` on `pangolin.pang.revelectronics.uk` or a Pangolin-protected app:

1. run `./bin/diagnose-crowdsec-403.sh revelectronics@tony_vps /home/revelectronics/docker/pangolin <public-ip>`
2. confirm whether CrowdSec has an active decision for that public IP
3. if yes, prefer allowlisting trusted fixed public IPs over disabling CrowdSec globally
4. keep the allowlist narrow and tied to stable home/office WAN IPs only

## Expected deliverables from the fresh session

At minimum:

1. a concise audit summary
2. the identified stack path
3. current running versions
4. whether an upgrade is needed
5. exact proposed upgrade path, including any breaking changes or gotchas
6. backup plan
7. execution and validation plan

If the user approves execution:

1. perform the upgrade safely
2. capture backup filenames
3. validate final health
4. report final versions and any follow-up recommendations

## Suggested session prompt

Use this in the new session:

```text
Read /Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/TONY_VPS_PANGOLIN_AUDIT_HANDOFF.md first and use it as the operating brief.

Then audit the Pangolin server at ssh revelectronics@tony_vps using the established runbooks and scripts in this repo.

Requirements:
- use the repo as the source of operational workflow
- audit first, do not make changes until the stack path, versions, and upgrade path are clear
- use official Pangolin and Traefik sources for any latest-version or upgrade-sequence claims
- do not stop unrelated containers
- if an upgrade is needed, plan it with incremental backups before each hop
- highlight breaking changes and gotchas before execution

Start by confirming the stack path and current running versions on the host, then report the audit summary and proposed plan.
```

## Notes for the next session

- This repo contains prior Pangolin operational knowledge, but the `vm890` clone scripts are not directly for `tony_vps`.
- The stack path and current versions are now known, but should still be re-validated before further changes.
- The next likely change on this host is ACME cleanup, not another Pangolin hop.
- Keep Gerbil and Traefik changes separate from ACME cleanup unless a deliberate combined maintenance window is planned.
