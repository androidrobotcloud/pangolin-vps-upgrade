# Pangolin Local DNS-01 Build and Audit

This document captures the working pattern for a local Pangolin test install that uses:

- a private DNS server
- Cloudflare DNS-01 wildcard certificates
- a Tailscale IP instead of a public VPS IP
- a separate Newt client for local container testing

It is based on a live audit completed on `2026-05-14`.

See also:

- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/PANGOLIN_NESTED_INCUS_LAN_LAB_BUILD.md`
- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/COLIMA_INCUS_BRIDGED_SANITY.md`
- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/VM890_OFFLINE_CLONE_RUNBOOK.md`

That companion guide captures the next evolution of this work: a nested Incus guest running Pangolin with its own LAN IP, instead of sharing only a parent VM or Tailscale address.

The offline clone runbook covers a different use case: preserving the real `vm890` VPS stack locally as an offline recovery artifact.

## Purpose

Use this guide when you want a local Pangolin lab that behaves as closely as possible to the working VPS, while still using:

- local Docker via OrbStack
- private DNS resolution
- a delegated wildcard subdomain
- Let’s Encrypt DNS-01 instead of HTTP-01

Target test domain used here:

- dashboard: `pangolin.pg.androidrobot.cloud`
- wildcard zone: `*.pg.androidrobot.cloud`
- test host Tailscale IP: `100.86.150.27`
- private DNS server: `192.168.1.6`

Reference docs:

- Pangolin wildcard docs: <https://docs.pangolin.net/self-host/advanced/wild-card-domains>
- Pangolin config docs: <https://docs.pangolin.net/self-host/advanced/config-file>
- Pangolin DNS/networking docs: <https://docs.pangolin.net/self-host/dns-and-networking>

Helper scripts in this repo:

- [scripts/colima_incus_bridged_sanity.sh](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/scripts/colima_incus_bridged_sanity.sh)
- [scripts/vm890_offline_clone.sh](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/scripts/vm890_offline_clone.sh)

## Audit Summary

### Working baseline

Known-good production-like scaffold:

- host: `hustler2025@vm890`
- stack path: `/home/hustler2025/docker/pangolin-vps`
- dashboard: `https://pangolin.pang.androidrobot.cloud`

Observed on audit:

- `pangolin:1.18.3`
- `gerbil:1.4.0`
- `traefik:v3.6.16`
- `crowdsec:latest`

Key baseline characteristics:

- Traefik and Gerbil share the network namespace with `network_mode: service:gerbil`
- Gerbil uses:
  - `--remoteConfig=http://pangolin:3001/api/v1/gerbil/get-config`
  - `--reportBandwidthTo=http://pangolin:3001/api/v1/gerbil/receive-bandwidth`
- wildcard preference is enabled
- Cloudflare is used for ACME
- CrowdSec and extra Traefik logging are present on the VPS only

### Local test install

Audited local stack:

- host: `pangolin@pangolin-local`
- stack path: `/opt/pangolin`
- dashboard: `https://pangolin.pg.androidrobot.cloud`

Observed on audit:

- `pangolin:ee-1.18.4`
- `gerbil:1.4.0`
- `traefik:v3.6` in compose, running `3.6.17` at runtime
- no CrowdSec in local stack

Local status at audit completion:

- Pangolin health endpoint passes
- Traefik serves a real Let’s Encrypt wildcard certificate
- Newt connects successfully
- dashboard over HTTPS returns `HTTP/2 200`

## Current Working Shape

### Pangolin stack

Current local stack files:

- compose: `/opt/pangolin/docker-compose.yml`
- Pangolin config: `/opt/pangolin/config/config.yml`
- Traefik static config: `/opt/pangolin/config/traefik/traefik_config.yml`
- Traefik dynamic config: `/opt/pangolin/config/traefik/dynamic_config.yml`

### Newt stack

Separate Newt compose project:

- `/opt/newt/docker-compose.yml`

Current local Newt pattern:

- connects to `https://pangolin.pg.androidrobot.cloud`
- includes `/var/run/docker.sock:/var/run/docker.sock`
- suitable for Docker-aware local container discovery tests

## Prerequisites

### Infrastructure

- Docker and `docker compose`
- Tailscale installed and connected
- a stable Tailscale IP for the local Pangolin host
- control of a Cloudflare zone or delegated sub-zone
- a DNS provider/API supported by Traefik ACME DNS-01
- a private DNS server if you want private-only resolution paths

### DNS

For this pattern, you need both of these to resolve to the Pangolin host:

- `pangolin.pg.androidrobot.cloud`
- `*.pg.androidrobot.cloud`

Recommended DNS model:

- public DNS handles ACME ownership and wildcard certificate issuance
- private DNS resolves the same names to the Tailscale IP for internal use

### Firewall and ports

Even in a local lab, make sure the relevant ports are reachable where needed:

- `80/tcp`
- `443/tcp`
- `443/udp` if using HTTP/3
- `51820/udp`
- `21820/udp`

If Newt or site hole punching is flaky, `21820/udp` is the first port to re-check.

## Build Recipe

### 1. Start from the working VPS scaffold

Use the working VPS as the reference shape, not the installer defaults.

Things to copy conceptually:

- service order and dependencies
- Gerbil command flags
- Traefik `network_mode: service:gerbil`
- config directory layout
- wildcard/domain naming style

Things that can differ locally:

- base domain
- dashboard URL
- Pangolin edition and exact version
- no CrowdSec if you want a smaller test stack
- DNS-01 Traefik resolver instead of HTTP-01

### 2. Configure Pangolin domain settings

In `config/config.yml`, make sure the local domain block is aligned:

```yaml
domains:
  domain1:
    base_domain: "pg.androidrobot.cloud"
    cert_resolver: "letsencrypt"
    prefer_wildcard_cert: true
```

Also set:

- `app.dashboard_url: "https://pangolin.pg.androidrobot.cloud"`
- `gerbil.base_endpoint: "pangolin.pg.androidrobot.cloud"`

### 3. Configure Gerbil correctly

The local stack must use the same Gerbil API endpoints as the working VPS:

```yaml
command:
  - --reachableAt=http://gerbil:3004
  - --generateAndSaveKeyTo=/var/config/key
  - --remoteConfig=http://pangolin:3001/api/v1/gerbil/get-config
  - --reportBandwidthTo=http://pangolin:3001/api/v1/gerbil/receive-bandwidth
```

If you point Gerbil at `/api/v1/` instead of the specific `gerbil/*` endpoints, configuration and bandwidth reporting will not behave correctly.

### 4. Switch Traefik to DNS-01

In `config/traefik/traefik_config.yml`, replace HTTP-01 with DNS-01 and provide the DNS provider token through the `traefik` service environment.

Cloudflare example:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"
      email: "admin@example.com"
      storage: "/letsencrypt/acme.json"
      caServer: "https://acme-v02.api.letsencrypt.org/directory"
```

Why the explicit resolvers mattered here:

- the local private resolver path worked for normal DNS answers
- it did not work cleanly for ACME authority/propagation checks
- forcing public resolvers made DNS-01 issuance succeed consistently

### 5. Configure dashboard wildcard certificate request correctly

In `config/traefik/dynamic_config.yml`, the dashboard router must request a cert for the correct zone:

```yaml
tls:
  certResolver: letsencrypt
  domains:
    - main: "pg.androidrobot.cloud"
      sans:
        - "*.pg.androidrobot.cloud"
```

Do not mix the parent zone with the delegated sub-zone.

Wrong:

```yaml
main: "androidrobot.cloud"
sans:
  - "*.pg.androidrobot.cloud"
```

Right:

```yaml
main: "pg.androidrobot.cloud"
sans:
  - "*.pg.androidrobot.cloud"
```

That mismatch was the biggest certificate blocker in the local build.

### 6. Rotate stale ACME state if needed

If Traefik already created a bad or stale `acme.json`, fix the configuration first, then force a fresh issuance:

```bash
docker compose down
mv config/letsencrypt/acme.json config/letsencrypt/acme.json.bak
docker compose up -d
docker compose logs -f traefik
```

This matches Pangolin’s wildcard guidance: clear old ACME state only after the resolver and router configuration are correct.

### 7. Add Newt separately

Use a separate compose project for Newt if you want the control plane and the site client decoupled during testing.

Example shape:

```yaml
services:
  newt:
    image: fosrl/newt
    container_name: newt
    restart: unless-stopped
    environment:
      - PANGOLIN_ENDPOINT=https://pangolin.pg.androidrobot.cloud
      - NEWT_ID=REPLACE
      - NEWT_SECRET=REPLACE
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
```

Use the Docker socket mount only if you want Docker-aware discovery of local containers.

## Validation Checklist

### DNS checks

From the local host:

```bash
getent hosts pangolin.pg.androidrobot.cloud
dig pangolin.pg.androidrobot.cloud
dig test.pg.androidrobot.cloud
```

Expected:

- `pangolin.pg.androidrobot.cloud` resolves to `100.86.150.27`
- wildcard labels under `pg.androidrobot.cloud` also resolve correctly

### TLS checks

```bash
curl -vkI https://pangolin.pg.androidrobot.cloud 2>&1 | sed -n '1,40p'
```

Expected:

- `HTTP/2 200`
- certificate subject `CN=pg.androidrobot.cloud`
- SAN includes `*.pg.androidrobot.cloud`
- issuer is Let’s Encrypt

### Pangolin and Traefik checks

```bash
cd /opt/pangolin
docker compose ps
docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && echo
docker compose logs --tail=120 pangolin gerbil traefik
```

Expected:

- Pangolin healthy
- Traefik starts the ACME provider without challenge failures
- dynamic config fetch succeeds after Pangolin is up

### Newt checks

```bash
cd /opt/newt
docker compose ps
docker compose logs --tail=80 newt
```

Expected:

- websocket connected
- tunnel established successfully
- ready to accept client connections

## Lessons Learned

### 1. Normal DNS success does not prove ACME DNS-01 will work

The local host could resolve the dashboard name before the build was fixed, but ACME still failed because authority/propagation lookups were going through a broken resolver chain.

### 2. The wildcard `main` domain and wildcard SAN must belong to the same zone

If you use `main: androidrobot.cloud` with `*.pg.androidrobot.cloud`, Traefik will try to validate the wrong scope.

### 3. Gerbil scaffolding matters more than it looks

Gerbil must use the exact Pangolin API paths from the working stack. A generic `/api/v1/` endpoint is not equivalent.

### 4. The local lab still depends on DNS design

Removing the manual `/etc/hosts` override was safe.

Restoring the default Tailscale resolvers was not safe for this lab, because `pangolin-local` then stopped resolving `pangolin.pg.androidrobot.cloud`.

Current state:

- `/etc/hosts` is clean
- `/etc/resolv.conf` currently points to `192.168.1.6`

Long-term improvement:

- replace the full resolver override with proper split DNS

### 5. Floating image tags reduce repeatability

The local compose file uses `traefik:v3.6`, but the running container was `3.6.17` at audit time.

That is convenient for drift forward, but not great for reproducible testing. Pin exact versions when you want deterministic rebuilds.

### 6. Secrets are currently inline

The local lab has sensitive values inline in compose/config files.

That is acceptable for a private throwaway lab, but it should be moved to `.env` or secret management before any wider sharing or backup export.

## Known Gotchas

### Startup noise that is usually okay

- brief Traefik `connection refused` errors while Pangolin is still booting
- Pangolin SMTP warning if mail is not configured

### Errors that need context

- repeated Gerbil `400 Bad Request` bandwidth reports can happen before a real site/resource topology is configured
- `Site last hole punch is too old` indicates UDP site registration trouble and usually means re-check `21820/udp` reachability

### Behavior observed during this audit

- historical Pangolin warnings about parsing an empty `acme.json` appeared before the new certificate was issued
- after the fresh issuance completed, the live certificate was valid and in use
- Newt connected successfully after deployment and after enabling Docker socket access

## Recommended Improvements

### Keep as-is for now

- private resolver at `192.168.1.6`
- local wildcard cert via Cloudflare DNS-01
- separate `/opt/newt` compose project

### Improve next

- pin exact `traefik` tag locally
- move Cloudflare token and Newt secrets into `.env`
- document split DNS so `resolv.conf` does not need a manual override
- decide whether the local lab should stay on Enterprise Pangolin or match the VPS edition exactly
- add SMTP only if mail flows matter in the lab

## Current Audit Verdict

The local Pangolin DNS-01 test build is working and is close enough to the VPS scaffold for meaningful testing.

What is working:

- dashboard HTTPS
- wildcard certificate issuance
- Pangolin health
- Newt connectivity
- Docker-aware Newt setup for local container testing

What is still lab-only rather than production-clean:

- resolver override in `/etc/resolv.conf`
- floating Traefik tag
- inline secrets
- some expected Gerbil noise until the full site/resource model is configured
