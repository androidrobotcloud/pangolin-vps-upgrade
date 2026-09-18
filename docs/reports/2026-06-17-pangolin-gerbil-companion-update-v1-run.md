Task:
pangolin-gerbil-companion-update-v1
Result:
passed
Confidence:
medium
Work class:
mutating
Files changed:
docs/reports/2026-06-17-pangolin-gerbil-companion-update-v1-run.md
Commands run:
./bin/check-vm890-profile.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.1
./bin/apply-gerbil-hop.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.1
./bin/verify-gerbil-version.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.1
./bin/verify-vm890-runtime.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.2
./bin/apply-gerbil-hop.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.2
./bin/verify-gerbil-version.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf 1.4.2
./bin/verify-vm890-runtime.sh specs/pangolin-gerbil-companion-update-v1.vm890.conf
Evidence:
- Canonical URL: https://pangolin.pang.androidrobot.cloud
- Executed Gerbil hop path: 1.4.1 1.4.2
- Backup files: 20260617-175357-pre-1.4.1.tar.gz 20260617-175554-pre-1.4.2.tar.gz
- Final Gerbil target reached: docker.io/fosrl/gerbil:1.4.2
- Pangolin remained on fosrl/pangolin:1.19.2
- Traefik remained on traefik:v3.6.16
- Unrelated containers remained present in docker ps output
Acceptance criteria:
- profile check passes before mutation: yes
- backup tarball created before each hop: yes
- Gerbil reached each target version in order: yes
- internal Pangolin health returned healthy after each hop: yes
- canonical dashboard HTTPS returned success after each hop: yes
- Pangolin, Traefik, CrowdSec, and unrelated containers remained present: yes
- final report written under docs/reports/: yes
Problems found:
- Traefik remains behind the current 3.6 patch line and latest 3.7 line
Problems fixed:
- Gerbil upgraded through the staged path 1.4.1 1.4.2
Stop conditions hit:
- none
Remaining risks:
- Traefik still requires its own companion workflow if you want current-line patching
- Browser SSH and other 1.19 companion-dependent features still need representative feature validation after this service-only update
Next recommended task:
- create a separate Traefik companion workflow if you want to patch the reverse proxy line next

Profile output:
== vm890 profile check ==
[pass] Hostname matches: vm890
[pass] Stack path exists: /home/hustler2025/docker/pangolin-vps
[pass] Required compose services present: pangolin gerbil traefik crowdsec
[pass] Expected image tags found
[pass] Dashboard URL matches runtime profile
[pass] Base domain matches runtime profile
[pass] Traefik network mode matches expected topology

Pre-upgrade runtime output:
== vm890 runtime verify ==
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services

Backup 1:
20260617-175357-pre-1.4.1.tar.gz

Hop 1 apply output:
[pass] Applied Gerbil hop to 1.4.1

Hop 1 version verify output:
[pass] Gerbil compose and runtime image both match docker.io/fosrl/gerbil:1.4.1

Hop 1 runtime output:
== vm890 runtime verify ==
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services

Backup 2:
20260617-175554-pre-1.4.2.tar.gz

Hop 2 apply output:
[pass] Applied Gerbil hop to 1.4.2

Hop 2 version verify output:
[pass] Gerbil compose and runtime image both match docker.io/fosrl/gerbil:1.4.2

Hop 2 runtime output:
== vm890 runtime verify ==
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services

Recent Gerbil logs:
INFO: 2026/06/17 16:57:17 Fetching remote config from http://pangolin:3001/api/v1/gerbil/get-config
INFO: 2026/06/17 16:57:25 Created WireGuard interface wg0
INFO: 2026/06/17 16:57:25 Assigned IP address 100.89.128.1/24 to interface wg0
INFO: 2026/06/17 16:57:25 Attempting to delete existing MSS clamping rule for chain INPUT
INFO: 2026/06/17 16:57:25 Attempting to delete existing MSS clamping rule for chain OUTPUT
INFO: 2026/06/17 16:57:25 Attempting to delete existing MSS clamping rule for chain FORWARD
INFO: 2026/06/17 16:57:25 Adding MSS clamping rule for chain INPUT
INFO: 2026/06/17 16:57:25 Successfully added and verified MSS clamping rule for chain INPUT
INFO: 2026/06/17 16:57:25 Adding MSS clamping rule for chain OUTPUT
INFO: 2026/06/17 16:57:25 Successfully added and verified MSS clamping rule for chain OUTPUT
INFO: 2026/06/17 16:57:25 Adding MSS clamping rule for chain FORWARD
INFO: 2026/06/17 16:57:25 Successfully added and verified MSS clamping rule for chain FORWARD
INFO: 2026/06/17 16:57:26 Adding WireGuard firewall rule 1: [-A INPUT -i wg0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT]
INFO: 2026/06/17 16:57:26 Successfully added and verified WireGuard firewall rule 1
INFO: 2026/06/17 16:57:26 Adding WireGuard firewall rule 2: [-A INPUT -i wg0 -p icmp --icmp-type 8 -j ACCEPT]
INFO: 2026/06/17 16:57:26 Successfully added and verified WireGuard firewall rule 2
INFO: 2026/06/17 16:57:26 Adding WireGuard firewall rule 3: [-A INPUT -i wg0 -j DROP]
INFO: 2026/06/17 16:57:26 Successfully added and verified WireGuard firewall rule 3
INFO: 2026/06/17 16:57:26 WireGuard firewall rules successfully configured for interface wg0
INFO: 2026/06/17 16:57:26 WireGuard interface wg0 created and configured
INFO: 2026/06/17 16:57:26 Peer 0sMXdXqd/dqPUg+78LhuhV8Kq/TbDFneQj55HqT8jhc= added successfully
INFO: 2026/06/17 16:57:26 Peer 8j80SvReQrBgjK3N+eBtNqq7Mpb0mWbTx7XMyS2eowo= added successfully
INFO: 2026/06/17 16:57:26 Peer Dqxhj8XtJ9hvEuD6RA4+j7UkttnKy/rpeUk9EZI6jg8= added successfully
INFO: 2026/06/17 16:57:26 Peer SLQAlqb2K+7et8aqaSydsYKYegyFUQbjM+lo9v3NxDA= added successfully
INFO: 2026/06/17 16:57:26 Peer KhC5RJR3L/Its+ptUJdBJev4NKtIvBUyw4r8JH/7fzw= added successfully
INFO: 2026/06/17 16:57:26 UDP server listening on :21820
INFO: 2026/06/17 16:57:26 Starting 20 packet workers (CPUs: 1)
INFO: 2026/06/17 16:57:26 Metrics endpoint enabled at /metrics
INFO: 2026/06/17 16:57:26 Starting HTTP server on :3004
INFO: 2026/06/17 16:57:26 Requesting initial proxy mappings
INFO: 2026/06/17 16:57:26 Received initial mappings, streaming decode
INFO: 2026/06/17 16:57:26 Loaded 8 initial proxy mappings

Final docker ps:
NAMES                       IMAGE                           STATUS
traefik                     traefik:v3.6.16                 Up 18 seconds
gerbil                      fosrl/gerbil:1.4.2              Up 22 seconds
pangolin                    fosrl/pangolin:1.19.2           Up 46 seconds (healthy)
crowdsec                    crowdsecurity/crowdsec:latest   Up 46 seconds (healthy)
filemanager-filebrowser-1   hurlenko/filebrowser            Up 14 hours
vps-dozzle                  amir20/dozzle:latest            Up 14 hours
beszel-agent                henrygd/beszel-agent            Up 3 months
borg-web-ui                 ainullcode/borg-ui:latest       Up 4 months (healthy)
hawser                      ghcr.io/finsys/hawser:latest    Up 4 months (healthy)
