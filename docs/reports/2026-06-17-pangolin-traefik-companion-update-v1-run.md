Task:
pangolin-traefik-companion-update-v1
Result:
passed
Confidence:
medium
Work class:
mutating
Files changed:
docs/reports/2026-06-17-pangolin-traefik-companion-update-v1-run.md
Commands run:
./bin/check-vm890-profile.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
./bin/verify-vm890-runtime.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.6.21
./bin/apply-traefik-hop.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.6.21
./bin/verify-traefik-version.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.6.21
./bin/verify-vm890-runtime.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
./bin/create-stack-backup.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.5
./bin/apply-traefik-hop.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.5
./bin/verify-traefik-version.sh specs/pangolin-traefik-companion-update-v1.vm890.conf v3.7.5
./bin/verify-vm890-runtime.sh specs/pangolin-traefik-companion-update-v1.vm890.conf
Evidence:
- Canonical URL: https://pangolin.pang.androidrobot.cloud
- Executed Traefik hop path: v3.6.21 v3.7.5
- Backup files: 20260617-180710-pre-v3.6.21.tar.gz 20260617-180902-pre-v3.7.5.tar.gz
- Final Traefik target reached: docker.io/traefik:v3.7.5
- Pangolin remained on fosrl/pangolin:1.19.2
- Gerbil remained on fosrl/gerbil:1.4.2
- Unrelated containers remained present in docker ps output
Acceptance criteria:
- profile check passes before mutation: yes
- backup tarball created before each hop: yes
- Traefik reached each target version in order: yes
- internal Pangolin health returned healthy after each hop: yes
- canonical dashboard HTTPS returned success after each hop: yes
- Pangolin, Gerbil, CrowdSec, and unrelated containers remained present: yes
- final report written under docs/reports/: yes
Problems found:
- none during execution
Problems fixed:
- Traefik upgraded through the staged path v3.6.21 v3.7.5
Stop conditions hit:
- none
Remaining risks:
- v3.7 introduced migration notes around BasicAuth and StripPrefix behavior; this stack did not show those patterns in the checked config files, but representative route testing is still wise
- this workflow validates dashboard HTTPS and container health, not every possible proxied route
Next recommended task:
- run a representative post-upgrade route test set, then decide whether any further companion cleanup is needed

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
20260617-180710-pre-v3.6.21.tar.gz

Hop 1 apply output:
[pass] Applied Traefik hop to v3.6.21

Hop 1 version verify output:
[pass] Traefik compose and runtime image both match docker.io/traefik:v3.6.21

Hop 1 runtime output:
== vm890 runtime verify ==
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services

Backup 2:
20260617-180902-pre-v3.7.5.tar.gz

Hop 2 apply output:
[pass] Applied Traefik hop to v3.7.5

Hop 2 version verify output:
[pass] Traefik compose and runtime image both match docker.io/traefik:v3.7.5

Hop 2 runtime output:
== vm890 runtime verify ==
[pass] Pangolin internal health is healthy
[pass] Canonical dashboard URL returned HTTP/2 200
[pass] Compose status includes healthy services

Recent Traefik logs:
{"level":"debug","entryPointName":"websecure","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","serviceName":"api-service@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/service.go:414","message":"Creating load-balancer"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","serviceName":"api-service@file","serverIndex":0,"URL":"http://pangolin:3000","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/service.go:472","message":"Creating server"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","serviceName":"api-service@file","middlewareName":"tracing","middlewareType":"TracingService","serviceName":"api-service@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/service.go:26","message":"Added outgoing tracing middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:26","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:40","message":"Setting up secureHeaders from {map[] map[Server: X-Forwarded-Proto:https X-Powered-By:] false [] [] [] [] [] 0 false [] [X-Forwarded-Host] map[X-Forwarded-Proto:https] 0xc000d38090 true true true false SAMEORIGIN true false     strict-origin-when-cross-origin  false <nil> <nil> <nil> <nil> <nil>}"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:46","message":"Setting up customHeaders/Cors from {map[] map[Server: X-Forwarded-Proto:https X-Powered-By:] false [] [] [] [] [] 0 false [] [X-Forwarded-Host] map[X-Forwarded-Proto:https] 0xc000d38090 true true true false SAMEORIGIN true false     strict-origin-when-cross-origin  false <nil> <nil> <nil> <nil> <nil>}"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"security-headers@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"crowdsec@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"tracing","middlewareType":"TracingRouter","routerName":"ws-router@file","serviceName":"api-service@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/router.go:37","message":"Added outgoing tracing middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:26","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:40","message":"Setting up secureHeaders from {map[] map[Server: X-Forwarded-Proto:https X-Powered-By:] false [] [] [] [] [] 0 false [] [X-Forwarded-Host] map[X-Forwarded-Proto:https] 0xc000d38090 true true true false SAMEORIGIN true false     strict-origin-when-cross-origin  false <nil> <nil> <nil> <nil> <nil>}"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:46","message":"Setting up customHeaders/Cors from {map[] map[Server: X-Forwarded-Proto:https X-Powered-By:] false [] [] [] [] [] 0 false [] [X-Forwarded-Host] map[X-Forwarded-Proto:https] 0xc000d38090 true true true false SAMEORIGIN true false     strict-origin-when-cross-origin  false <nil> <nil> <nil> <nil> <nil>}"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"security-headers@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"crowdsec@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"tracing","middlewareType":"TracingRouter","routerName":"next-router@file","serviceName":"next-service@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/router.go:37","message":"Added outgoing tracing middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:26","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:40","message":"Setting up secureHeaders from {map[] map[Server: X-Forwarded-Proto:https X-Powered-By:] false [] [] [] [] [] 0 false [] [X-Forwarded-Host] map[X-Forwarded-Proto:https] 0xc000d38090 true true true false SAMEORIGIN true false     strict-origin-when-cross-origin  false <nil> <nil> <nil> <nil> <nil>}"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"security-headers@file","middlewareType":"Headers","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/headers/headers.go:46","message":"Setting up customHeaders/Cors from {map[] map[Server: X-Forwarded-Proto:https X-Powered-By:] false [] [] [] [] [] 0 false [] [X-Forwarded-Host] map[X-Forwarded-Proto:https] 0xc000d38090 true true true false SAMEORIGIN true false     strict-origin-when-cross-origin  false <nil> <nil> <nil> <nil> <nil>}"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"security-headers@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"crowdsec@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"tracing","middlewareType":"TracingRouter","routerName":"api-router@file","serviceName":"api-service@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/router.go:37","message":"Added outgoing tracing middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"16-moodle-router@http","middlewareName":"badger@http","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"16-moodle-router@http","middlewareName":"crowdsec@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/middleware.go:33","message":"Adding tracing to middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"16-moodle-router@http","middlewareName":"tracing","middlewareType":"TracingRouter","routerName":"16-moodle-router@http","serviceName":"16-moodle-service@http","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/router.go:37","message":"Added outgoing tracing middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"16-moodle-router@http","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"16-moodle-router@http","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","middlewareName":"traefik-internal-recovery","middlewareType":"Recovery","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/recovery/recovery.go:25","message":"Creating middleware"}
{"level":"debug","entryPointName":"web","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"web","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"traefik","middlewareName":"tracing","middlewareType":"SemConvServerMetrics","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/semconv.go:40","message":"Creating middleware"}
{"level":"debug","entryPointName":"traefik","middlewareName":"tracing","middlewareType":"TracingEntryPoint","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/middlewares/observability/entrypoint.go:37","message":"Creating middleware"}
{"level":"debug","entryPointName":"websecure","routerName":"ws-router@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/server/router/tcp/manager.go:197","message":"Adding route for pangolin.pang.androidrobot.cloud with TLS options default"}
{"level":"debug","entryPointName":"websecure","routerName":"next-router@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/server/router/tcp/manager.go:197","message":"Adding route for pangolin.pang.androidrobot.cloud with TLS options default"}
{"level":"debug","entryPointName":"websecure","routerName":"api-router@file","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/server/router/tcp/manager.go:197","message":"Adding route for pangolin.pang.androidrobot.cloud with TLS options default"}
{"level":"debug","entryPointName":"websecure","routerName":"16-moodle-router@http","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/server/router/tcp/manager.go:197","message":"Adding route for moodle.pang.androidrobot.cloud with TLS options default"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"ws-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:494","message":"Trying to challenge certificate for domain [pangolin.pang.androidrobot.cloud] found in HostSNI rule"}
{"level":"warn","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"next-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`) && !PathPrefix(`/api/v1`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:854","message":"Domain \"pang.androidrobot.cloud\" is duplicated in the configuration or validated by the domain {androidrobot.cloud [*.androidrobot.cloud]}. It will be processed once."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"16-moodle-router@http","rule":"Host(`moodle.pang.androidrobot.cloud`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:494","message":"Trying to challenge certificate for domain [moodle.pang.androidrobot.cloud] found in HostSNI rule"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"api-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`) && PathPrefix(`/api/v1`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:494","message":"Trying to challenge certificate for domain [pangolin.pang.androidrobot.cloud] found in HostSNI rule"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"api-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`) && PathPrefix(`/api/v1`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:969","message":"Looking for provided certificate(s) to validate [\"pangolin.pang.androidrobot.cloud\"]..."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"api-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`) && PathPrefix(`/api/v1`)","domains":["pangolin.pang.androidrobot.cloud"],"time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:1013","message":"No ACME certificate generation required for domains"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"ws-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:969","message":"Looking for provided certificate(s) to validate [\"pangolin.pang.androidrobot.cloud\"]..."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"ws-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`)","domains":["pangolin.pang.androidrobot.cloud"],"time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:1013","message":"No ACME certificate generation required for domains"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:969","message":"Looking for provided certificate(s) to validate [\"androidrobot.cloud\" \"*.androidrobot.cloud\"]..."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","domains":["androidrobot.cloud","*.androidrobot.cloud"],"time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:1015","message":"Domains need ACME certificates generation for domains \"androidrobot.cloud,*.androidrobot.cloud\"."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:731","message":"Loading ACME certificates [androidrobot.cloud *.androidrobot.cloud]..."}
{"level":"debug","providerName":"letsencrypt.acme","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:292","message":"Building ACME client..."}
{"level":"debug","providerName":"letsencrypt.acme","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:298","message":"https://acme-v02.api.letsencrypt.org/directory"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:969","message":"Looking for provided certificate(s) to validate [\"*.pang.androidrobot.cloud\"]..."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","domains":["*.pang.androidrobot.cloud"],"time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:1013","message":"No ACME certificate generation required for domains"}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"16-moodle-router@http","rule":"Host(`moodle.pang.androidrobot.cloud`)","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:969","message":"Looking for provided certificate(s) to validate [\"moodle.pang.androidrobot.cloud\"]..."}
{"level":"debug","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"16-moodle-router@http","rule":"Host(`moodle.pang.androidrobot.cloud`)","domains":["moodle.pang.androidrobot.cloud"],"time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:1013","message":"No ACME certificate generation required for domains"}
{"level":"debug","providerName":"letsencrypt.acme","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:341","message":"Using DNS Challenge provider: cloudflare"}
{"level":"debug","providerName":"letsencrypt.acme","time":"2026-06-17T17:10:53Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:374","message":"Using HTTP Challenge provider."}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:53Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [androidrobot.cloud, *.androidrobot.cloud] acme: Obtaining bundled SAN certificate"}
{"level":"debug","time":"2026-06-17T17:10:54Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/loadbalancer/wrr/wrr.go:251","message":"Service selected by WRR: http://pangolin:3002"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:54Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [*.androidrobot.cloud] AuthURL: https://acme-v02.api.letsencrypt.org/acme/authz/2795059816/722839126946"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:54Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [androidrobot.cloud] AuthURL: https://acme-v02.api.letsencrypt.org/acme/authz/2795059816/723568346126"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:54Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [*.androidrobot.cloud] acme: authorization already valid; skipping challenge"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:54Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [androidrobot.cloud] acme: Could not find solver for: tls-alpn-01"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:54Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [androidrobot.cloud] acme: use http-01 solver"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:54Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] [androidrobot.cloud] acme: Trying to solve HTTP-01"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:55Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] Skipping deactivating of valid auth: https://acme-v02.api.letsencrypt.org/acme/authz/2795059816/722839126946"}
{"level":"debug","lib":"lego","time":"2026-06-17T17:10:55Z","caller":"github.com/go-acme/lego/v4@v4.35.2/log/logger.go:48","message":"[INFO] Deactivating auth: https://acme-v02.api.letsencrypt.org/acme/authz/2795059816/723568346126"}
{"level":"error","providerName":"letsencrypt.acme","acmeCA":"https://acme-v02.api.letsencrypt.org/directory","providerName":"letsencrypt.acme","ACME CA":"https://acme-v02.api.letsencrypt.org/directory","routerName":"next-router@file","rule":"Host(`pangolin.pang.androidrobot.cloud`) && !PathPrefix(`/api/v1`)","error":"unable to generate a certificate for the domains [androidrobot.cloud *.androidrobot.cloud]: error: one or more domains had a problem:\n[androidrobot.cloud] invalid authorization: acme: error: 400 :: urn:ietf:params:acme:error:dns :: no valid A records found for androidrobot.cloud; no valid AAAA records found for androidrobot.cloud\n","domains":["androidrobot.cloud","*.androidrobot.cloud"],"time":"2026-06-17T17:10:55Z","caller":"github.com/traefik/traefik/v3/pkg/provider/acme/provider.go:577","message":"Unable to obtain ACME certificate for domains"}
{"level":"debug","time":"2026-06-17T17:10:55Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/loadbalancer/wrr/wrr.go:251","message":"Service selected by WRR: http://pangolin:3000"}
{"level":"debug","time":"2026-06-17T17:10:55Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/loadbalancer/wrr/wrr.go:251","message":"Service selected by WRR: http://pangolin:3000"}
{"level":"debug","time":"2026-06-17T17:10:56Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/loadbalancer/wrr/wrr.go:251","message":"Service selected by WRR: http://pangolin:3000"}
{"level":"debug","time":"2026-06-17T17:10:56Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/loadbalancer/wrr/wrr.go:251","message":"Service selected by WRR: http://pangolin:3000"}
{"level":"debug","time":"2026-06-17T17:10:57Z","caller":"github.com/traefik/traefik/v3/pkg/server/service/loadbalancer/wrr/wrr.go:251","message":"Service selected by WRR: http://pangolin:3002"}

Final docker ps:
NAMES                       IMAGE                           STATUS
traefik                     traefik:v3.7.5                  Up 9 seconds
gerbil                      fosrl/gerbil:1.4.2              Up 31 seconds
pangolin                    fosrl/pangolin:1.19.2           Up 53 seconds (healthy)
crowdsec                    crowdsecurity/crowdsec:latest   Up 53 seconds (healthy)
filemanager-filebrowser-1   hurlenko/filebrowser            Up 14 hours
vps-dozzle                  amir20/dozzle:latest            Up 14 hours
beszel-agent                henrygd/beszel-agent            Up 3 months
borg-web-ui                 ainullcode/borg-ui:latest       Up 4 months (healthy)
hawser                      ghcr.io/finsys/hawser:latest    Up 4 months (healthy)
