Task:
pangolin-staged-upgrade-v1
Result:
passed
Confidence:
medium
Work class:
mutating
Files changed:
docs/reports/2026-06-17-pangolin-staged-upgrade-v1-planner-proof.md
Commands run:
./bin/check-vm890-profile.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.18.4
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.18.4
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.18.4
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
./bin/create-pangolin-backup.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.19.2
./bin/apply-pangolin-hop.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.19.2
./bin/verify-pangolin-version.sh specs/pangolin-staged-upgrade-v1.vm890.conf 1.19.2
./bin/verify-vm890-runtime.sh specs/pangolin-staged-upgrade-v1.vm890.conf
Evidence:
- Backup files created:
  - 20260617-172847-pre-1.18.4.tar.gz
  - 20260617-173235-pre-1.19.2.tar.gz
- Pangolin runtime image reached `docker.io/fosrl/pangolin:1.18.4` and then `docker.io/fosrl/pangolin:1.19.2`
- Canonical dashboard URL returned `HTTP/2 200` after both hops
- Pangolin internal health returned `{"message":"Healthy"}` after both hops
- Unrelated containers remained present and running on the host
- Pangolin migration logs show successful `1.19.0` and `1.19.1` migrations and an automatic Badger config bump to `v1.4.1`
Acceptance criteria:
- profile check passes before mutation: yes
- backup tarball created before each hop: yes
- Pangolin reached each target version in order: yes
- internal Pangolin health returned healthy after each hop: yes
- canonical dashboard HTTPS returned success after each hop: yes
- unrelated containers remained running: yes
- final report written under docs/reports/: yes
Problems found:
- The original public HTTPS verifier was too eager immediately after Traefik restart and hit a transient SSL connect failure before the route fully settled
- Pangolin 1.19 migration updated the Badger version in Traefik config automatically, which changes the live companion state even though Traefik itself was not version-bumped
Problems fixed:
- Pangolin upgraded successfully from `1.18.3 -> 1.18.4 -> 1.19.2`
- `bin/verify-vm890-runtime.sh` now retries the public HTTPS check during restart settle windows
- `bin/apply-pangolin-hop.sh` now refuses downgrade attempts on rerun
Stop conditions hit:
- none
Remaining risks:
- Gerbil remains on `1.4.0`
- Traefik remains on `v3.6.16`
- Browser SSH, RDP, and VNC feature paths from Pangolin 1.19 are not fully validated by this workflow
- The Traefik logs still show legacy ACME noise for `androidrobot.cloud`, which is separate from this Pangolin upgrade path
Next recommended task:
- rerun the read-only runtime audit and upgrade-readiness audit with updated current-state specs
