# VM890 Offline Clone Runbook

This runbook documents the local offline backup clone of the Pangolin stack from:

- source host: `hustler2025@vm890`
- source stack path: `/home/hustler2025/docker/pangolin-vps`

It is intended as:

- an offline preserved copy of the current VPS Pangolin build
- a restorable local reference
- a safe recovery artifact

It is not intended as:

- a second live production instance
- a DNS cutover target
- a parallel always-on control plane

## Repeatable Helper

The clone workflow is now scripted here:

- [scripts/vm890_offline_clone.sh](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/scripts/vm890_offline_clone.sh)

Default usage:

```bash
./scripts/vm890_offline_clone.sh
```

Useful variants:

```bash
./scripts/vm890_offline_clone.sh --profile vm890-backup-2 --guest pangolin-vm890-backup-2
./scripts/vm890_offline_clone.sh --start-stack
./scripts/vm890_offline_clone.sh --keep-access-log
```

The script handles:

- source access check
- Colima profile creation/start
- nested Incus guest creation
- Docker installation in the guest
- live Pangolin stack export from `vm890`
- stack import into the guest
- exact source image cache by digest
- Incus snapshot creation

Related helper:

- [scripts/colima_incus_bridged_sanity.sh](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/scripts/colima_incus_bridged_sanity.sh)

Use the sanity script when you want to validate a fresh Colima + Incus network path before you stage a clone into it.

## Current Backup Target

Local target created on `2026-05-15`:

- Colima profile: `vm890-backup`
- Colima runtime: `incus`
- nested Incus guest: `pangolin-vm890-backup`
- guest OS: `Ubuntu 22.04`
- guest architecture: `aarch64`
- guest stack path: `/home/hustler2025/docker/pangolin-vps`

## What Was Preserved

The clone preserves the Pangolin stack only:

- `docker-compose.yml`
- active `config/`
- live Pangolin database state under `config/db/`
- live Gerbil key material under `config/key`
- live Let’s Encrypt state under `config/letsencrypt/acme.json`
- active Traefik config
- active CrowdSec config and data

The clone also caches the exact source image set by digest:

- `fosrl/pangolin@sha256:94e04ae48eec8a2f2c9925f1f12b8016abe5093f41f6f9829a0fca98e06b7fe0`
- `fosrl/gerbil@sha256:887355e66deac61df9583d9df23e630897f785a8e20bc66081c66e40687cc713`
- `traefik@sha256:f79c88ed5252ae1e31c757a9796d751461ddb502437b8d8526db9e12605a82eb`
- `crowdsecurity/crowdsec@sha256:6ca53ad26196ca59ddd4fa692a586b73d8fcde085046163b9ca2f04887dca563`

## What Was Intentionally Excluded

The backup intentionally excludes backup clutter and non-essential history:

- `config/db/backups/`
- `config/traefik/backup/`
- `config/traefik/logs/access.log`
- `*.bak`
- `*.bak.*`
- any separate `pangolin-vps-backups` tarballs on `vm890`

## Snapshot

Initial snapshot taken after staging:

- `initial-offline-clone`

That gives you a clean point-in-time rollback before any accidental start or edit.

## Current Measured Size

Measured on the local target right after staging:

- Incus guest root disk usage: about `1.88 GiB`

That includes:

- guest OS
- Docker installation
- cloned Pangolin stack files
- cached source images

## Architecture

```text
Mac
  -> Colima profile vm890-backup
    -> Incus guest pangolin-vm890-backup
      -> Docker
        -> cloned Pangolin stack from vm890
```

## Important Caveat

The source VPS is:

- `Ubuntu 22.04`
- `x86_64`

The local backup guest is:

- `Ubuntu 22.04`
- `aarch64`

So the preserved Docker images are exact by digest, but if you ever run them locally they will run as `linux/amd64` images on an `aarch64` guest, which means emulation.

This is acceptable for an offline backup artifact.

It is not the ideal shape for a performance-sensitive always-on deployment.

## Safety Rule

Treat this guest as powered-off backup inventory unless you are actively restoring or testing.

Default stance:

```text
Do not start the stack unless there is a specific reason.
```

Why:

- it contains real config and secrets
- it contains the live Pangolin database state
- it contains the live certificate state
- starting it carelessly could create control-plane identity collisions

## Filesystem Layout

Inside the guest:

- stack root:
  - `/home/hustler2025/docker/pangolin-vps`
- compose file:
  - `/home/hustler2025/docker/pangolin-vps/docker-compose.yml`
- config root:
  - `/home/hustler2025/docker/pangolin-vps/config`

## Basic Lifecycle

### Check the Colima profile

```bash
colima list -v
colima status --profile vm890-backup
```

### Open a shell to the Colima VM

```bash
colima ssh --profile vm890-backup
```

### Inspect the backup guest

```bash
incus list
incus info pangolin-vm890-backup
```

### Enter the backup guest

```bash
incus exec pangolin-vm890-backup -- bash
```

### Validate the stack files without starting services

```bash
cd /home/hustler2025/docker/pangolin-vps
docker compose config
find config -maxdepth 2 -type f | sort | sed -n '1,120p'
```

## Safe Bring-Up Guidance

If you ever need to boot this stack locally for inspection or recovery testing, use this order.

### 1. Snapshot first

From the Colima VM:

```bash
incus snapshot create pangolin-vm890-backup pre-start-YYYYMMDD
```

### 2. Decide whether the environment must stay isolated

Preferred default:

- keep it off shared DNS
- do not expose it to public-facing clients
- avoid reusing the live hostname in an active LAN path unless you are deliberately doing a restore drill

### 3. Start only when necessary

Inside the guest:

```bash
cd /home/hustler2025/docker/pangolin-vps
docker compose up -d
```

### 4. Validate quickly

```bash
docker compose ps
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
docker compose logs --tail=120 pangolin gerbil traefik crowdsec
```

### 5. Shut it back down when done

```bash
docker compose down
```

## ASCII Flow

```text
Live VPS source
  vm890
    |
    | cloned stack/config/state
    v
Local Colima profile
  vm890-backup
    |
    v
Incus guest
  pangolin-vm890-backup
    |
    v
Docker
  pangolin / gerbil / traefik / crowdsec
```

## Restore Intent

This clone is most useful for:

- recovering exact compose/config state
- recovering the Pangolin database state
- recovering Gerbil key material
- recovering Traefik and Let’s Encrypt state
- understanding the real live VPS scaffold later

## Key Lessons

### 1. Exact stack preservation is not the same as “copy every file on the server”

The useful boundary was the Pangolin stack itself, not the VPS as a whole.

### 2. Root-owned files matter

`acme.json` could not be copied safely with a plain user tar read, so the Docker-based read path was the right approach.

### 3. Logs are not the same as state

The Traefik access log was large and expensive to copy, but it was not required to preserve a restorable stack.

### 4. Exact image digests matter for a real offline clone

Preserving only `docker-compose.yml` is not enough if you later want the clone to behave like the source without chasing whatever “latest” means at that future date.

### 5. An offline backup should start from a snapshot

The Incus snapshot gives you a trustworthy rollback point before experiments or accidental startup drift.

## Quick Reference

### Start Colima profile

```bash
colima start vm890-backup
```

### Stop Colima profile

```bash
colima stop vm890-backup
```

### List Incus snapshots

```bash
colima ssh --profile vm890-backup -- incus info pangolin-vm890-backup
```

### Restore the initial snapshot

```bash
colima ssh --profile vm890-backup -- incus restore pangolin-vm890-backup initial-offline-clone
```

## Current Verdict

The `vm890` Pangolin stack is now preserved locally as a focused offline clone:

- stack files copied
- runtime state copied
- backup clutter excluded
- source image set cached by digest
- nested Docker target built
- rollback snapshot created

That is a good backup posture for the Pangolin stack itself.
