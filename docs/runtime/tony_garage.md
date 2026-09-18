# Runtime Profile: tony_garage
Last verified: not yet established by environment-status-scan-v1.
## Environment
- canonical ID: `tony_garage`
- owner: Tony
- managed by: repository operator on Tony's behalf with full operational/admin authority
- role: Tony's on-premises work/bus-garage environment
## Current intent
Garage workloads currently depend on Tony VPS Pangolin. Target: separate local-first Pangolin/ingress and authoritative local DNS path, with required applications reachable from the garage LAN when 5G WAN is unavailable.
## Known platform
- TP-Link Archer NX500 v2.0
- UGREEN NAS
- Incus
- existing Hermes/ramp application instances
- planned infrastructure/ingress Incus instance
- planned Technitium DNS and local Pangolin Enterprise
## Runtime evidence
Intentionally conservative until the first dedicated read-only collector proves concrete host, instance, service, address and version facts.
## Safety
Do not treat `tony_vps` as this environment. Cross-environment migration work must be explicitly authorised.
