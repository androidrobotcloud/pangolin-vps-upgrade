# Pangolin Upgrade Checklist

Use this as the short operational checklist while performing the upgrade.

## Inputs

- Server: `________________`
- SSH user: `________________`
- Stack path: `________________`
- Public FQDN: `________________`
- Current Pangolin: `________________`
- Target Pangolin: `________________`
- Current Gerbil: `________________`
- Target Gerbil: `________________`

## Pre-flight

- [ ] Confirm SSH access works
- [ ] `docker compose ps` reviewed
- [ ] current `docker-compose.yml` reviewed
- [ ] custom Traefik/CrowdSec config noted
- [ ] release path confirmed from official notes
- [ ] rollback directory created

## Pangolin hop 1

- [ ] backup created
- [ ] Pangolin tag updated
- [ ] `docker compose down`
- [ ] `docker compose pull pangolin`
- [ ] `docker compose up -d`
- [ ] internal Pangolin health passes
- [ ] public HTTPS returns `200`
- [ ] logs reviewed for migration success

Backup file:

`________________________________________`

## Pangolin hop 2

- [ ] backup created
- [ ] Pangolin tag updated
- [ ] stack restarted
- [ ] internal Pangolin health passes
- [ ] public HTTPS returns `200`
- [ ] logs reviewed for migration success

Backup file:

`________________________________________`

## Pangolin hop 3

- [ ] backup created
- [ ] Pangolin tag updated
- [ ] stack restarted
- [ ] internal Pangolin health passes
- [ ] public HTTPS returns `200`
- [ ] logs reviewed for migration success

Backup file:

`________________________________________`

## Optional Gerbil hop

- [ ] backup created
- [ ] Gerbil tag updated
- [ ] stack restarted
- [ ] Pangolin health passes
- [ ] Gerbil logs show config fetch and peers added
- [ ] public HTTPS returns `200`

Backup file:

`________________________________________`

## Optional Traefik patch hop

- [ ] backup created
- [ ] Traefik tag updated
- [ ] `docker compose pull traefik`
- [ ] `docker compose up -d traefik`
- [ ] Pangolin health passes
- [ ] public HTTPS returns `200`
- [ ] Traefik logs reviewed

Backup file:

`________________________________________`

## Final record

- Final Pangolin tag: `________________`
- Final Gerbil tag: `________________`
- Final Traefik tag: `________________`
- Final CrowdSec tag: `________________`

## Latest recorded live result

- Server: `tony_vps`
- SSH user: `revelectronics`
- Stack path: `/home/revelectronics/docker/pangolin`
- Public FQDN: `pangolin.pang.revelectronics.uk`
- Final Pangolin tag: `1.18.4`
- Final Gerbil tag: `1.3.1`
- Final Traefik tag: `v3.4.1`
- Final CrowdSec tag: `latest`
- Residual follow-up: ACME stale-domain cleanup tracked in `TO_DO.md`

## Rollback trigger conditions

- [ ] migration fails
- [ ] Pangolin health endpoint fails after settle time
- [ ] public HTTPS does not recover
- [ ] Gerbil cannot fetch config or recreate peers
- [ ] private resources fail in a way not explained by expected transient restart behavior
