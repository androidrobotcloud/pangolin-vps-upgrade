Task:
pangolin-readonly-audit-v1
Result:
passed
Confidence:
high
Work class:
read-only
Files changed:
docs/reports/2026-06-17-pangolin-readonly-audit-v1-run.md
Commands run:
./bin/check-vm890-profile.sh specs/pangolin-readonly-audit-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-readonly-audit-v1.vm890.conf
ssh hustler2025@vm890 'cd /home/hustler2025/docker/pangolin-vps && docker compose ps'
ssh hustler2025@vm890 'cd /home/hustler2025/docker/pangolin-vps && docker compose images'
Evidence:
- Canonical URL: https://pangolin.pang.androidrobot.cloud
- Profile check passed
- Runtime verify passed
- Compose services: pangolin, gerbil, traefik, crowdsec
Acceptance criteria:
- profile check passes: yes
- internal Pangolin health returns healthy: yes
- canonical dashboard HTTPS check returns success: yes
- final report written under docs/reports/: yes
Problems found:
- local incus-lan lab is stopped and not suitable as the first workflow target today
- legacy repo docs contain broader operational context than this bounded worker workflow needs
Problems fixed:
- added minimum worker-operable contract surface for one read-only workflow
- added deterministic helper path for vm890 audit
Stop conditions hit:
- none
Remaining risks:
- runtime facts may drift later; rerun the profile check before trusting old reports
- this workflow does not validate upgrade readiness or non-dashboard routes
Next recommended task:
- consider workflow two only after this read-only audit path is reused successfully

Profile output:
== vm890 profile check ==
[pass] Hostname matches: vm890
[pass] Stack path exists: /home/hustler2025/docker/pangolin-vps
[pass] Required compose services present: pangolin gerbil traefik crowdsec
[pass] Expected image tags found
[pass] Dashboard URL matches runtime profile
[pass] Base domain matches runtime profile
[pass] Traefik network mode matches expected topology

Runtime verify output:
== vm890 runtime verify ==
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services

Compose ps:
NAME       IMAGE                                     COMMAND                  SERVICE    CREATED        STATUS                  PORTS
crowdsec   docker.io/crowdsecurity/crowdsec:latest   "/bin/bash /docker_s…"   crowdsec   13 hours ago   Up 13 hours (healthy)   0.0.0.0:6060->6060/tcp, [::]:6060->6060/tcp
gerbil     docker.io/fosrl/gerbil:1.4.0              "/entrypoint.sh --re…"   gerbil     13 hours ago   Up 13 hours             0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:3479->3479/udp, [::]:3479->3479/udp, 0.0.0.0:21820->21820/udp, [::]:21820->21820/udp, 0.0.0.0:3479->3479/tcp, [::]:3479->3479/tcp, 0.0.0.0:51820->51820/udp, [::]:51820->51820/udp
pangolin   docker.io/fosrl/pangolin:1.18.3           "docker-entrypoint.s…"   pangolin   13 hours ago   Up 13 hours (healthy)   
traefik    docker.io/traefik:v3.6.16                 "/entrypoint.sh --co…"   traefik    13 hours ago   Up 13 hours             

Compose images:
CONTAINER           REPOSITORY               TAG                 PLATFORM            IMAGE ID            SIZE                CREATED
crowdsec            crowdsecurity/crowdsec   latest              linux/amd64         552773629ac4        344MB               292 years ago
gerbil              fosrl/gerbil             1.4.0               linux/amd64         2f1d952b4f6e        39MB                292 years ago
pangolin            fosrl/pangolin           1.18.3              linux/amd64         c23ea87394a4        1.35GB              292 years ago
traefik             traefik                  v3.6.16             linux/amd64         c654007d711b        188MB               292 years ago
