# Pangolin Incremental Upgrade Runbook

This runbook is for safely upgrading a self-hosted Pangolin Docker Compose stack across multiple release boundaries, with a rollback tarball before each hop.

It is based on a successful live upgrade of:

- `pangolin 1.15.4 -> 1.16.2 -> 1.17.1 -> 1.18.1`
- `gerbil 1.3.0 -> 1.3.1`

Primary references:

- Official update method: <https://docs.pangolin.net/self-host/how-to-update>
- Target release example: <https://github.com/fosrl/pangolin/releases/tag/1.18.1>

## Scope and principles

- Upgrade only the Pangolin stack containers.
- Do not stop unrelated containers on the same host.
- Follow Pangolin's incremental release path, not a direct jump across multiple minors.
- Take a full stack backup before each version hop.
- Validate after each hop before proceeding.
- Keep companion services stable unless there is a clear reason to change them.

## 1. Pre-flight audit

SSH to the server and inspect the live stack.

```bash
ssh USER@HOST
cd /path/to/pangolin-stack
docker compose ps
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}'
sed -n '1,260p' docker-compose.yml
find config -maxdepth 3 -type f | sort | sed -n '1,200p'
du -sh config config/* 2>/dev/null | sort -h
```

Confirm:

- current `fosrl/pangolin` tag
- current `fosrl/gerbil` tag
- mounted config/data layout
- any local Traefik or CrowdSec customizations
- whether files are root-owned

## 2. Determine the upgrade path

Never jump straight to the target if Pangolin docs or release notes require stepping through intermediate versions.

Example path used successfully:

- `1.15.4 -> 1.16.2`
- `1.16.2 -> 1.17.1`
- `1.17.1 -> 1.18.1`

Use the latest patch within each required minor line when possible.

## 3. Known breaking changes and gotchas

Review release notes before touching the stack. For the `1.15.x -> 1.18.x` path, these mattered most:

- `1.16.x`
  - adds SSH-related changes
  - may create SSH CA material during migration
- `1.17.x`
  - migrates single-role behavior into multi-role RBAC tables
  - good moment to re-check org roles and invite flows after upgrade
- `1.17.1`
  - host-mode private resources may require Newt restart after update
- `1.18.x`
  - migrates health checks, status history, and private-resource network data
  - if using Enterprise cert scraping, default expected path is `config/letsencrypt/acme.json`

Operational gotchas discovered during live work:

- root-owned files can make normal `tar` backups incomplete
- Traefik may briefly fail HTTPS checks during restart even when the stack is healthy moments later
- Pangolin's internal health endpoint is usually only reachable from inside the container, not from the host
- custom Traefik/CrowdSec tuning means a narrow-scope upgrade is safer than refreshing everything at once

## 4. Backup method

If files may be root-owned, use a Docker helper container to create a complete backup tarball.

Create a backup directory once:

```bash
mkdir -p /path/to/pangolin-backups
```

Create a full backup before each hop:

```bash
stamp=$(date +%Y%m%d-%H%M%S)
backup_name=${stamp}-pre-<TARGET>.tar.gz

docker run --rm \
  -v /path/to/pangolin-stack:/src:ro \
  -v /path/to/pangolin-backups:/backups \
  alpine:3.20 \
  sh -lc "cd /src && tar -czpf /backups/$backup_name docker-compose.yml config"
```

Verify:

```bash
ls -lh /path/to/pangolin-backups/$backup_name
```

Recommended naming:

- `YYYYMMDD-HHMMSS-pre-1.16.2.tar.gz`
- `YYYYMMDD-HHMMSS-pre-1.17.1.tar.gz`
- `YYYYMMDD-HHMMSS-pre-1.18.1.tar.gz`
- `YYYYMMDD-HHMMSS-pre-gerbil-1.3.1.tar.gz`

## 5. Validation commands

Use these after every hop.

Internal Pangolin health:

```bash
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
```

Public HTTPS check:

```bash
curl -k -I -sS https://YOUR_PANGOLIN_FQDN | sed -n '1,12p'
```

Stack status:

```bash
docker compose ps
docker compose images
```

Recent logs:

```bash
docker compose logs --tail=80 pangolin gerbil traefik crowdsec
```

What to look for:

- Pangolin migration completes successfully
- Pangolin reports API, internal API, and web UI started
- Gerbil fetches remote config and adds peers successfully
- public HTTPS returns `HTTP/2 200`

## 6. Standard Pangolin hop procedure

For each version hop:

1. Create a backup tarball.
2. Edit only the Pangolin image tag in `docker-compose.yml`.
3. Restart only this compose stack.
4. Wait for health checks.
5. Run validations.
6. Only proceed if healthy.

Update the tag:

```bash
sed -i 's#docker.io/fosrl/pangolin:OLD#docker.io/fosrl/pangolin:NEW#' docker-compose.yml
```

If direct editing is awkward because of ownership, use a helper container:

```bash
docker run --rm \
  -v /path/to/pangolin-stack:/work \
  alpine:3.20 \
  sh -lc "sed -i 's#docker.io/fosrl/pangolin:OLD#docker.io/fosrl/pangolin:NEW#' /work/docker-compose.yml"
```

Restart the stack:

```bash
docker compose down
docker compose pull pangolin
docker compose up -d
```

Notes:

- `docker compose down` affects only this stack, not unrelated containers.
- This is acceptable when the whole Pangolin stack must restart together because of shared network mode and dependencies.

## 7. Example command sequence

### 7.1 Upgrade `1.15.4 -> 1.16.2`

```bash
docker run --rm -v "$PWD:/work" alpine:3.20 \
  sh -lc "sed -i 's#docker.io/fosrl/pangolin:1.15.4#docker.io/fosrl/pangolin:1.16.2#' /work/docker-compose.yml"

docker compose down
docker compose pull pangolin
docker compose up -d
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
curl -k -I -sS https://YOUR_PANGOLIN_FQDN | sed -n '1,12p'
docker compose logs --tail=80 pangolin gerbil traefik crowdsec
```

Expected migration pattern:

- `Starting migrations from version 1.15.4`
- `Migrations to run: 1.16.0`

### 7.2 Upgrade `1.16.2 -> 1.17.1`

```bash
docker run --rm -v "$PWD:/work" alpine:3.20 \
  sh -lc "sed -i 's#docker.io/fosrl/pangolin:1.16.2#docker.io/fosrl/pangolin:1.17.1#' /work/docker-compose.yml"

docker compose down
docker compose pull pangolin
docker compose up -d
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
curl -k -I -sS https://YOUR_PANGOLIN_FQDN | sed -n '1,12p'
docker compose logs --tail=80 pangolin gerbil traefik crowdsec
```

Expected migration pattern:

- `Starting migrations from version 1.16.0`
- `Migrations to run: 1.17.0`

### 7.3 Upgrade `1.17.1 -> 1.18.1`

```bash
docker run --rm -v "$PWD:/work" alpine:3.20 \
  sh -lc "sed -i 's#docker.io/fosrl/pangolin:1.17.1#docker.io/fosrl/pangolin:1.18.1#' /work/docker-compose.yml"

docker compose down
docker compose pull pangolin
docker compose up -d
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
curl -k -I -sS https://YOUR_PANGOLIN_FQDN | sed -n '1,12p'
docker compose logs --tail=120 pangolin gerbil traefik crowdsec
```

Expected migration pattern:

- `Starting migrations from version 1.17.0`
- `Migrations to run: 1.18.0`

## 8. Optional Gerbil companion update

Do this only after Pangolin is stable.

Backup first, then update the image tag:

```bash
docker run --rm -v "$PWD:/work" alpine:3.20 \
  sh -lc "sed -i 's#docker.io/fosrl/gerbil:1.3.0#docker.io/fosrl/gerbil:1.3.1#' /work/docker-compose.yml"
```

Restart:

```bash
docker compose down
docker compose pull gerbil
docker compose up -d
```

Validate:

```bash
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
docker compose logs --tail=80 gerbil
curl -k -I -sS https://YOUR_PANGOLIN_FQDN | sed -n '1,12p'
```

Healthy `gerbil 1.3.1` startup should show:

- remote config fetched from Pangolin
- WireGuard interface created
- peers added successfully
- HTTP server started on `:3004`

## 9. Rollback procedure

If a hop fails:

1. Stop and remove the Pangolin stack.
2. Restore `docker-compose.yml` and `config/` from the backup tarball.
3. Bring the stack back up.
4. Re-check health and logs.

Example:

```bash
cd /path/to
mv pangolin-stack pangolin-stack.failed.$(date +%Y%m%d-%H%M%S)
mkdir -p pangolin-stack
tar -xzpf /path/to/pangolin-backups/ROLLBACK.tar.gz -C pangolin-stack
cd pangolin-stack
docker compose up -d
```

If you prefer in-place restore:

```bash
cd /path/to/pangolin-stack
tar -xzpf /path/to/pangolin-backups/ROLLBACK.tar.gz
docker compose up -d
```

Use the matching tarball for the failed target:

- failed while going to `1.16.2` -> restore `pre-1.16.2`
- failed while going to `1.17.1` -> restore `pre-1.17.1`
- failed while going to `1.18.1` -> restore `pre-1.18.1`

## 10. Post-upgrade checks worth doing manually

- log into the dashboard
- review users, roles, and invites after `1.17.x`
- review health checks and status history after `1.18.x`
- test a representative private resource
- if using host-mode private resources, restart affected Newt agents if needed
- confirm wildcard/private routing still behaves as expected

## 11. Recommended streamlined workflow for the next host

For the next instance, use this order:

1. audit current version, config ownership, and customizations
2. calculate the exact release path
3. prepare a backup directory
4. use Docker-based backups only
5. perform one Pangolin hop at a time
6. validate before the next hop
7. update Gerbil only after Pangolin is stable
8. record backup names and final running tags

This keeps the process fast while still preserving a clean rollback point at every boundary.
