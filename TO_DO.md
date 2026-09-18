# TO_DO

## ACME cleanup follow-up for `tony_vps`

### Current state

- Pangolin upgrade completed successfully to `1.18.4`
- Gerbil upgraded successfully to `1.3.1`
- Traefik remains on `v3.4.1`
- Pangolin dashboard is healthy at `https://pangolin.pang.revelectronics.uk`

### ACME issue summary

Traefik is still attempting to renew certificates for domains that do not appear to belong on this VPS anymore.

Confirmed during investigation:

- `config/traefik/dynamic_config.yml` declares:
  - `revelectronics.uk`
  - `*.revelectronics.uk`
  - `pang.revelectronics.uk`
  - `*.pang.revelectronics.uk`
- `config/letsencrypt/acme.json` still contains stored entries for:
  - `pangolin.pang.revelectronics.uk`
  - `dash.pang.revelectronics.uk`
  - `nas.pang.revelectronics.uk`
  - `revelnas.pang.revelectronics.uk`
  - `nextcloud-nas.pang.revelectronics.uk`
  - `nextcloud-nas.revelectronics.uk`
  - `nextcloud.revelectronics.uk`
  - `*.pang.revelectronics.uk`
  - `revelectronics.uk`
  - `*.revelectronics.uk`
- Traefik logs show renewal failures for:
  - `nextcloud.revelectronics.uk`
  - `revelectronics.uk`
- Public DNS checks during the session showed:
  - `pangolin.pang.revelectronics.uk` resolves publicly
  - `pang.revelectronics.uk` resolves publicly
  - `revelectronics.uk` had no public answer from the check point used
  - `nextcloud.revelectronics.uk` did not present as a public VPS-facing record and appeared tied to private/internal resolution

### Likely root cause

- The Traefik domain declaration is broader than the set of names that should currently terminate on this VPS.
- Traefik is trying to maintain certificates for stale or non-public names.
- The config still includes `httpChallenge`, but DNS-01 is the intended ACME mode.

### Safe cleanup plan

1. Back up:
   - `docker-compose.yml`
   - `config/traefik/traefik_config.yml`
   - `config/traefik/dynamic_config.yml`
   - `config/letsencrypt/acme.json`
2. Confirm the intended certificate scope before editing:
   - likely keep only `pangolin.pang.revelectronics.uk` and/or `*.pang.revelectronics.uk`
   - decide whether `revelectronics.uk` and `*.revelectronics.uk` should remain on this VPS
3. Remove `httpChallenge` from Traefik static config if DNS-01 is the intended standard.
4. Reduce `tls.domains` in Traefik dynamic config to only the domains that should still be issued here.
5. Restart only the Pangolin compose stack.
6. Re-check Traefik logs to confirm it stops attempting renewals for stale names.
7. If stale cert targets remain in `acme.json`, prune or regenerate only after backup and only once the intended domain set is confirmed.

### Caution

- Do not clear `acme.json` blindly.
- Do not remove currently served domains without confirming the intended final certificate set.
- Keep this as a separate change from the completed Pangolin version upgrade.
