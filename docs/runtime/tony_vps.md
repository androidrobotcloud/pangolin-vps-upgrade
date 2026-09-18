# Runtime Profile: tony_vps

This file is a bootstrap runtime profile for your friend's Pangolin host. It is intentionally minimal and must be verified live before any mutation.

## Environment

- name: `tony_vps`
- host: `revelectronics@tony_vps`
- role: friend's live Pangolin VPS
- confidence: `high`
- profile verified: `2026-08-24`

## Canonical Entrypoint

- dashboard URL: `https://pangolin.pang.revelectronics.uk`

## Stack Path

- compose project path: `/home/revelectronics/docker/pangolin`

## Backend Entrypoints

- Pangolin internal health: `http://localhost:3001/api/v1/` from inside the `pangolin` container
- Pangolin API backend in Traefik dynamic config: `http://pangolin:3000`
- Pangolin UI backend in Traefik dynamic config: `http://pangolin:3002`

## Service / Container Names

- `pangolin`
- `gerbil`
- `traefik`
- `crowdsec`

## Verified Running Versions

Verified on `2026-08-24`:

- `fosrl/pangolin:ee-1.21.1`
- `fosrl/gerbil:1.3.1`
- `traefik:v3.4.1`
- `crowdsecurity/crowdsec:latest`

## Live Edition

- Pangolin runtime image: `Enterprise`
- License activation status: `not verified active`

## Live Health

- Pangolin internal health: healthy
- Canonical dashboard HTTPS: `HTTP/2 200`
- Pangolin stack services present: `pangolin`, `gerbil`, `traefik`, `crowdsec`

## Preserved Rollback Data

- `/home/revelectronics/docker/pangolin-backups/20260824-173222-pre-1.19.4.tar.gz`
- `/home/revelectronics/docker/pangolin-backups/20260824-173551-pre-1.20.0.tar.gz`
- `/home/revelectronics/docker/pangolin-backups/20260824-173901-pre-1.21.1.tar.gz`
- `/home/revelectronics/docker/pangolin-backups/20260824-174142-pre-ee-1.21.1.tar.gz`

## Known Facts

- A prior CrowdSec false-positive helper was written against this host and stack path.
- This repo's existing bounded worker contract is for `vm890`, not for `tony_vps`.
- Any worker using this host should first prove the live runtime facts and then create host-specific specs before mutation.
- Traefik shares the Gerbil network namespace via `network_mode: service:gerbil`.
- `config/config.yml` currently declares dashboard URL `https://pangolin.pang.revelectronics.uk` and base domain `pang.revelectronics.uk`.

## Approved Secret Source

- operator SSH access for `revelectronics@tony_vps` via local SSH config and agent

## Required Caution

- Do not reuse `vm890` specs against `tony_vps`.
- Do not assume versions, edition, or companion-service layout match `vm890`.
- Do not mutate until hostname, stack path, compose services, image tags, dashboard URL, and current health are all verified live.
