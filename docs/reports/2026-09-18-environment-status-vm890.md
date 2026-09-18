Task: environment-status-scan-v1
Environment ID: vm890
Scan timestamp: 2026-09-18T15:44:24Z
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
gerbil              fosrl/gerbil             1.5.0               linux/amd64         8026bed047cc        39.2MB              292 years ago
pangolin            fosrl/pangolin           ee-1.22.2           linux/amd64         0b47fe1dc4b2        1.19GB              292 years ago
traefik             traefik                  v3.7.11             linux/amd64         6f8cb8f771e1        194MB               292 years ago
Compose status:
NAME       IMAGE                                     COMMAND                  SERVICE    CREATED         STATUS                   PORTS
crowdsec   docker.io/crowdsecurity/crowdsec:latest   "/bin/bash /docker_s…"   crowdsec   2 minutes ago   Up 2 minutes (healthy)   0.0.0.0:6060->6060/tcp, [::]:6060->6060/tcp
gerbil     docker.io/fosrl/gerbil:1.5.0              "/entrypoint.sh --re…"   gerbil     2 minutes ago   Up About a minute        0.0.0.0:80->80/tcp, [::]:80->80/tcp, 0.0.0.0:443->443/tcp, [::]:443->443/tcp, 0.0.0.0:3479->3479/udp, [::]:3479->3479/udp, 0.0.0.0:21820->21820/udp, [::]:21820->21820/udp, 0.0.0.0:3479->3479/tcp, [::]:3479->3479/tcp, 0.0.0.0:51820->51820/udp, [::]:51820->51820/udp
pangolin   docker.io/fosrl/pangolin:ee-1.22.2        "docker-entrypoint.s…"   pangolin   2 minutes ago   Up 2 minutes (healthy)   
traefik    docker.io/traefik:v3.7.11                 "/entrypoint.sh --co…"   traefik    2 minutes ago   Up About a minute        
Differences: compare with docs/runtime/vm890.md and previous scan
ENVIRONMENTS.md comparison: review standard fields; update only material changes
Problems fixed: none; infrastructure scan is read-only
