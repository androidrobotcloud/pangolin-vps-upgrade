Task:
pangolin-readonly-audit-v1
Result:
passed
Confidence:
high
Work class:
read-only
Files changed:
docs/reports/2026-08-24-pangolin-readonly-audit-v1-run.md
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
none observed during this run
Problems fixed:
none; read-only audit only
Stop conditions hit:
- none
Remaining risks:
- runtime facts may drift later; rerun the profile check before trusting old reports
- this workflow does not validate upgrade readiness or non-dashboard routes
Next recommended task:
- rerun this workflow before relying on stale runtime assumptions, or add workflow two only after this audit path is reused successfully

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
NAME       IMAGE                                     COMMAND                  SERVICE    CREATED          STATUS                    PORTS
crowdsec   docker.io/crowdsecurity/crowdsec:latest   "/bin/bash /docker_s…"   crowdsec   27 minutes ago   Up 27 minutes (healthy)   0.0.0.0:6060->6060/tcp, [::]:6060->6060/tcp
gerbil     docker.io/fosrl/gerbil:1.5.0              "/entrypoint.sh --re…"   gerbil     27 minutes ago   Up 26 minutes             0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:3479->3479/udp, [::]:3479->3479/udp, 0.0.0.0:21820->21820/udp, [::]:21820->21820/udp, 0.0.0.0:3479->3479/tcp, [::]:3479->3479/tcp, 0.0.0.0:51820->51820/udp, [::]:51820->51820/udp
pangolin   docker.io/fosrl/pangolin:ee-1.21.1        "docker-entrypoint.s…"   pangolin   27 minutes ago   Up 27 minutes (healthy)   
traefik    docker.io/traefik:v3.7.11                 "/entrypoint.sh --co…"   traefik    27 minutes ago   Up 26 minutes             

Compose images:
CONTAINER           REPOSITORY               TAG                 PLATFORM            IMAGE ID            SIZE                CREATED
crowdsec            crowdsecurity/crowdsec   latest              linux/amd64         552773629ac4        344MB               292 years ago
gerbil              fosrl/gerbil             1.5.0               linux/amd64         8026bed047cc        39.2MB              292 years ago
pangolin            fosrl/pangolin           ee-1.21.1           linux/amd64         96b8eeee32c8        1.21GB              292 years ago
traefik             traefik                  v3.7.11             linux/amd64         6f8cb8f771e1        194MB               292 years ago
