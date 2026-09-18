Task:
pangolin-upgrade-readiness-audit-v1
Result:
passed
Confidence:
high
Work class:
read-only
Files changed:
docs/reports/2026-06-17-pangolin-upgrade-readiness-audit-v1-planner-proof.md
Commands run:
./bin/check-vm890-profile.sh specs/pangolin-upgrade-readiness-audit-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-upgrade-readiness-audit-v1.vm890.conf
./bin/verify-pangolin-upgrade-readiness.sh specs/pangolin-upgrade-readiness-audit-v1.vm890.conf
Evidence:
- Canonical URL: https://pangolin.pang.androidrobot.cloud
- Runtime profile check passed
- Runtime health verification passed
- Official upstream release facts were gathered from Pangolin docs and official GitHub release APIs
- Readiness analysis was computed from live vm890 images plus official release metadata
Acceptance criteria:
- profile check passes: yes
- internal Pangolin health returns healthy: yes
- canonical dashboard HTTPS check returns success: yes
- official upstream release facts are gathered from primary sources: yes
- report states current runtime, current-line latest, and overall latest: yes
- report includes read-only proposed version path and gotcha notes: yes
- final report written under docs/reports/: yes
Problems found:
- Pangolin is behind both the current 1.18 patch line and the latest 1.19 line
- Gerbil is behind the current 1.4 patch line
- Traefik is behind both the current 3.6 patch line and the latest 3.7 line
- Badger plugin is behind the latest 1.4 line
Problems fixed:
none; read-only readiness audit only
Stop conditions hit:
- none
Remaining risks:
- this workflow does not execute or validate any upgrade
- upstream release facts can drift; rerun this workflow before a maintenance window
- companion service changes should still be treated separately from Pangolin core migration work
Next recommended task:
- create a separate mutating handoff only if you want staged backup-backed execution of the Pangolin upgrade path

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

Upgrade readiness output:
== pangolin upgrade readiness ==
Official upstream sources:
- Pangolin update docs: https://docs.pangolin.net/self-host/how-to-update
- Pangolin latest stable: 1.19.2 (2026-06-12)
- Gerbil latest stable: 1.4.2 (2026-06-13)
- Badger latest stable: v1.4.1 (2026-06-03)
- Traefik latest stable: v3.7.5 (2026-06-10)

Version audit:
- Pangolin: current 1.18.3 | current-line latest 1.18.4 | overall latest 1.19.2 | status behind-current-line-and-overall
- Gerbil: current 1.4.0 | current-line latest 1.4.2 | overall latest 1.4.2 | status behind-current-line
- Badger: current v1.3.1 | current-line latest v1.3.1 | overall latest v1.4.1 | status current-on-line-behind-overall
- Traefik: current v3.6.16 | current-line latest v3.6.21 | overall latest v3.7.5 | status behind-current-line-and-overall

Read-only proposed version paths:
- Pangolin: 1.18.4 -> 1.19.2
- Gerbil: 1.4.2
- Badger: v1.4.1
- Traefik: v3.6.21 -> v3.7.5

Breaking changes and gotchas to review before mutating work:
- Official update docs say to back up the config directory and update incrementally between versions.
- Existing repo runbook says to keep companion service changes separate from Pangolin migrations where possible.
- Pangolin 1.19 official release summary adds browser-based SSH, RDP, and VNC, improved Pangolin SSH, automatic site updates, labels, and resource policies.
- Inference from official summaries: no explicit breaking change is highlighted for 1.19, but it is still a minor-version jump and should be validated with representative site, SSH, and browser-access checks after upgrade.
- Traefik is behind both on the current 3.6 line and the overall 3.7 line; treat any Traefik move as a separate companion task.
- Badger plugin is behind the latest release; because it is tied to Traefik middleware behavior, keep it separate from Pangolin core migrations.
