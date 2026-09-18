Task: environment-status-scan-v1
Environment ID: vm890
Scan timestamp: 2026-09-18T16:10:35Z
Result: evidence-collected
Previous baseline: docs/reports/2026-09-18-environment-status-vm890.md
Observed evidence:
- hostname: vm890
- stack: /home/hustler2025/docker/pangolin-vps
- Pangolin health: {"message":"Healthy"}
- canonical HTTP: 200
Compose images:
CONTAINER           REPOSITORY               TAG                 PLATFORM            IMAGE ID            SIZE                CREATED
crowdsec            crowdsecurity/crowdsec   latest              linux/amd64         552773629ac4        344MB               292 years ago
gerbil              fosrl/gerbil             1.5.1               linux/amd64         68209f96d6bf        39.5MB              292 years ago
pangolin            fosrl/pangolin           ee-1.23.0           linux/amd64         4a57e728ac4f        1.1GB               292 years ago
traefik             traefik                  v3.7.13             linux/amd64         f9309349d2c1        195MB               292 years ago
Compose status:
NAME       IMAGE                                     COMMAND                  SERVICE    CREATED              STATUS                        PORTS
crowdsec   docker.io/crowdsecurity/crowdsec:latest   "/bin/bash /docker_s…"   crowdsec   About a minute ago   Up About a minute (healthy)   0.0.0.0:6060->6060/tcp, [::]:6060->6060/tcp
gerbil     docker.io/fosrl/gerbil:1.5.1              "/entrypoint.sh --re…"   gerbil     About a minute ago   Up About a minute             0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:3479->3479/udp, [::]:3479->3479/udp, 0.0.0.0:21820->21820/udp, [::]:21820->21820/udp, 0.0.0.0:3479->3479/tcp, [::]:3479->3479/tcp, 0.0.0.0:51820->51820/udp, [::]:51820->51820/udp
pangolin   docker.io/fosrl/pangolin:ee-1.23.0        "docker-entrypoint.s…"   pangolin   About a minute ago   Up About a minute (healthy)   
traefik    docker.io/traefik:v3.7.13                 "/entrypoint.sh --co…"   traefik    About a minute ago   Up 57 seconds                 
Differences: compare with docs/runtime/vm890.md and previous scan
ENVIRONMENTS.md comparison: review standard fields; update only material changes
Problems fixed: none; infrastructure scan is read-only
