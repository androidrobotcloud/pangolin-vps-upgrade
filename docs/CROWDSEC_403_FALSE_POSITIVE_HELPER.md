# CrowdSec 403 False-Positive Helper

Use this when a user reports a sudden `403` on Pangolin or a Pangolin-protected site and there is a chance CrowdSec blocked the request before Pangolin handled it.

## Goal

Confirm the exact pattern we saw on `tony_vps`:

- a visible `403`
- an active CrowdSec decision for the user's public IP
- Traefik access-log `403` entries for that IP with no upstream `ServiceName`
- a CrowdSec alert such as `crowdsecurity/http-probing`

When those are all true, the safest immediate workaround is:

- allowlist trusted fixed public IPs

## Read-only helper

Run:

```bash
./bin/diagnose-crowdsec-403.sh \
  revelectronics@tony_vps \
  /home/revelectronics/docker/pangolin \
  109.157.221.152
```

The helper:

- checks active CrowdSec decisions for the IP
- checks recent CrowdSec alerts for the IP
- inspects recent Traefik access-log rows for that IP
- highlights whether the `403` is likely happening in CrowdSec middleware before Pangolin

## How to interpret the result

Strong match:

- active CrowdSec decision exists for the IP
- recent `403` rows exist for the same IP
- those `403` rows have no upstream `ServiceName`

That means the block is IP-based at Traefik/CrowdSec, not login-based in Pangolin.

## Safe next step

If the IP is trusted and stable:

1. clear the current decision for that IP
2. add the IP to a narrow CrowdSec allowlist
3. re-test access

Do not disable CrowdSec globally just to get past this symptom.

## Why this matters for future sessions

Another AI can use this helper to avoid confusing:

- Pangolin auth denial
- resource-level access denial
- CrowdSec IP remediation

They can quickly prove whether the issue is truly CrowdSec-driven and choose the smallest safe workaround.
