Task:
tony-vps-community-to-enterprise-v1
Result:
partial pass; latest stable Community upgrade completed, same-version Enterprise runtime conversion completed, stopped before license activation because no usable license key was proven from the documented host materials
Confidence:
high
Work class:
mutating
Files changed:
docs/runtime/tony_vps.md
docs/reports/2026-08-24-tony-vps-community-to-enterprise-v1-run.md
specs/pangolin-readonly-audit-v1.tony_vps.conf
specs/pangolin-upgrade-readiness-audit-v1.tony_vps.conf
specs/pangolin-staged-upgrade-v1.tony_vps.conf
specs/pangolin-enterprise-conversion-v1.tony_vps.conf
remote: /home/revelectronics/docker/pangolin/docker-compose.yml
Commands run:
ssh revelectronics@tony_vps 'hostname && cd /home/revelectronics/docker/pangolin && docker compose ps && docker compose images'
./bin/check-vm890-profile.sh specs/pangolin-readonly-audit-v1.tony_vps.conf
./bin/verify-vm890-runtime.sh specs/pangolin-readonly-audit-v1.tony_vps.conf
./bin/verify-pangolin-upgrade-readiness.sh specs/pangolin-upgrade-readiness-audit-v1.tony_vps.conf
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.19.4
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.19.4
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.19.4
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.20.0
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.20.0
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.20.0
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.21.1
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.21.1
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.tony_vps.conf 1.21.1
./bin/create-stack-backup.sh specs/pangolin-enterprise-conversion-v1.tony_vps.conf ee-1.21.1
ssh revelectronics@tony_vps 'cd /home/revelectronics/docker/pangolin && sed -i "s#docker.io/fosrl/pangolin:1.21.1#docker.io/fosrl/pangolin:ee-1.21.1#" docker-compose.yml && docker compose down && docker compose pull pangolin && docker compose up -d'
ssh revelectronics@tony_vps 'cd /home/revelectronics/docker/pangolin && docker compose ps && docker compose images && docker exec pangolin curl -fsS http://localhost:3001/api/v1/ && curl -k -I https://pangolin.pang.revelectronics.uk'
Evidence:
- Live host proved as `vm895`, not assumed from `vm890`
- Proven stack path: `/home/revelectronics/docker/pangolin`
- Official Pangolin update guidance requires backup first and incremental updates: [docs.pangolin.net/self-host/how-to-update](https://docs.pangolin.net/self-host/how-to-update)
- Official latest stable Pangolin release proven as `1.21.1`; staged hop path used: `1.18.4 -> 1.19.4 -> 1.20.0 -> 1.21.1`: [github.com/fosrl/pangolin/releases](https://github.com/fosrl/pangolin/releases)
- Official Traefik latest stable observed during readiness audit as `v3.7.11`, while host remained on `v3.4.1`: [github.com/traefik/traefik/releases](https://github.com/traefik/traefik/releases)
- Backup tarballs preserved before each mutating step:
  - `20260824-173222-pre-1.19.4.tar.gz`
  - `20260824-173551-pre-1.20.0.tar.gz`
  - `20260824-173901-pre-1.21.1.tar.gz`
  - `20260824-174142-pre-ee-1.21.1.tar.gz`
- Final runtime state:
  - `pangolin`: `docker.io/fosrl/pangolin:ee-1.21.1`
  - `gerbil`: `docker.io/fosrl/gerbil:1.3.1`
  - `traefik`: `docker.io/traefik:v3.4.1`
  - `crowdsec`: `docker.io/crowdsecurity/crowdsec:latest`
- Final health checks passed:
  - Pangolin internal API: `{"message":"Healthy"}`
  - Canonical dashboard: `HTTP/2 200`
- Short post-conversion logs showed:
  - Pangolin migrations completed successfully from `1.21.0`
  - Pangolin API and UI listeners started
  - Traefik plugins loaded
Acceptance criteria:
- `tony_vps` runtime profile is verified and updated from live facts: yes
- host-specific specs exist and pass read-only checks before mutation: yes
- every mutating step has a corresponding rollback tarball: yes
- Pangolin reaches the latest stable Community version first: yes
- Pangolin then reaches the matching `ee-<same-version>` image: yes
- internal Pangolin health is healthy after each stage: yes
- canonical dashboard HTTPS returns success after each stage: yes
- unrelated containers outside the Pangolin stack remain untouched: yes
- final report is written under `docs/reports/`: yes
Problems found:
- Handoff source set had a contradiction: `docs/runtime/CURRENT_STATE.md` and `docs/runtime/vm890.md` were listed both as required reads and forbidden paths; treated as read-only source material only
- Backup helper commands often hung from the local exec session even when the tarball had already been created on-host; direct host validation was required to prove success
- `verify-pangolin-version.sh` can give a false mismatch if run in parallel with `apply-pangolin-hop.sh`; post-hop rerun passed each time
- Traefik logs still show unrelated ACME renewal noise for `nextcloud.revelectronics.uk` due to missing DNS records for that hostname
- No license key was proven available in the host stack files or documented runtime materials when the task reached Enterprise activation
Problems fixed:
- Pangolin upgraded safely from `1.18.4` to `1.21.1` in documented incremental hops with preserved rollback tarballs
- Pangolin runtime converted from Community `1.21.1` to Enterprise `ee-1.21.1` at the same version with a fresh pre-conversion backup
- Host-specific runtime/spec bootstrap was created so future automation does not need to guess from `vm890`
Stop conditions hit:
- license key missing when the thread reached the Enterprise activation step
Remaining risks:
- Pangolin is running the Enterprise image, but the report does not prove an active Enterprise license in the UI
- Gerbil remains on `1.3.1` and Traefik remains on `v3.4.1`; this matched the requested stage order, but both are behind latest stable
- Traefik ACME renewal noise for `nextcloud.revelectronics.uk` remains and should be cleaned up separately to reduce certificate churn and log noise
- Local backup helper behavior is noisy; future runs should treat on-host tarball existence as the real success signal
Next recommended task:
- provide the Enterprise license key and complete `/admin/license` activation, then run a separate companion-service review for Gerbil and Traefik on `tony_vps`
