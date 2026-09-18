# Pangolin Nested Incus LAN Lab Build

This document captures the working pattern we proved on `2026-05-15`:

- Colima on macOS
- Incus inside the bridged Colima VM
- a nested Incus guest with its own LAN IP
- Docker inside that nested guest
- Pangolin, Gerbil, Traefik, and Newt running in that nested guest

This is the cleanest build pattern we found for the specific goal:

> Pangolin should have its own LAN IP, instead of only being reachable through the parent VM.

## Purpose

Use this guide when you want a safe parallel Pangolin lab on your LAN without replacing the existing working install.

In the tested layout:

- the parent Colima VM stays a host for Incus
- a nested Incus guest becomes the actual Pangolin runtime
- that nested guest gets its own DHCP lease on the LAN

## Related Docs And Helpers

Useful companion files in this repo:

- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/COLIMA_INCUS_BRIDGED_SANITY.md`
- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/scripts/colima_incus_bridged_sanity.sh`
- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/VM890_OFFLINE_CLONE_RUNBOOK.md`
- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/scripts/vm890_offline_clone.sh`

Use them for two different jobs:

- `colima_incus_bridged_sanity.sh` proves the nested Incus/LAN assumptions before you deploy Pangolin
- `vm890_offline_clone.sh` stages a focused offline clone of the real VPS stack into a fresh Colima + Incus target

## Final Proven Topology

```text
Mac host
  |
  | Colima profile: incus-lan
  v
+-----------------------------------------------------------+
| Colima VM                                                 |
| LAN IP: 192.168.1.190                                     |
| Runtime: Incus                                            |
|                                                           |
|  col0     -> LAN-facing NIC inside the VM                 |
|  incusbr0 -> private Incus bridge for normal nested labs  |
|                                                           |
|  Nested Incus guest: pangolin-lan                         |
|    NIC mode: macvlan parent=col0                          |
|    LAN IP: 192.168.1.106                                  |
|    Docker: installed and working                          |
|    Pangolin stack: running                                |
|    Newt: running                                          |
+-----------------------------------------------------------+
  |
  +--> Router / DHCP
  |
  +--> Other LAN clients can reach 192.168.1.106 directly
```

## Why This Build Exists

Earlier testing proved three separate things:

1. A bridged Colima VM can get a real LAN IP.
2. Nested Incus works normally on the private `incusbr0` network.
3. Pangolin still does not have its own LAN IP in that private-only model.

The missing requirement was:

```text
Pangolin itself must appear as its own LAN host.
```

The successful answer was not a custom `br0` experiment. It was:

```text
Incus guest NIC: nictype=macvlan, parent=col0
```

## Key Decision

We intentionally kept this as a parallel lab on `192.168.1.106`.

That means:

- no cutover from the current working install
- no production DNS repoint
- safe room to test Newt, sites, resources, and container discovery

## Prerequisites

### macOS host

- Colima installed
- a bridged Colima profile using your real LAN interface, such as `en0`
- the `incus-lan` profile running

### Colima VM

- Incus running and healthy
- an actual LAN-facing NIC inside the VM
- tested here as `col0`

### LAN / DHCP

- router DHCP available
- preferably a DHCP reservation for the nested Pangolin guest MAC once the IP is known

### Pangolin control plane

- DNS and certificate model already understood from the earlier DNS-01 work
- working hostname pattern already established:
  - `pangolin.pg.androidrobot.cloud`
  - `*.pg.androidrobot.cloud`

## Safe Network Testing Path

We tested networking in this order:

```text
1. Prove the Colima VM itself gets a LAN IP
2. Prove nested Incus works on the default private bridge
3. Prove a disposable nested guest can get its own LAN DHCP lease
4. Build Pangolin only after step 3 succeeds
```

That avoided debugging Pangolin and networking at the same time.

## Important Network Finding

The disposable test guest attached with:

```text
nictype=macvlan,parent=col0
```

got its own LAN IP successfully and was reachable from the Mac host and other LAN clients.

It was not reachable from the parent Colima VM.

That is expected `macvlan` behavior.

## Macvlan Reachability Model

```text
Mac host / LAN client  ---->  pangolin-lan (192.168.1.106)   works
Colima parent VM       ---->  pangolin-lan (192.168.1.106)   fails
```

This is the most important gotcha in the whole build.

Do not treat that parent-to-child isolation as a bug.

## Build Steps

### 1. Start the bridged Colima profile

Target profile used here:

- `incus-lan`

Observed VM LAN IP during the working test:

- `192.168.1.190`

### 2. Confirm the VM has a real LAN-facing interface

In the working test:

- VM interface: `col0`

That is the interface the nested Pangolin guest used as its `macvlan` parent.

### 3. Launch the nested Pangolin guest

The nested guest used for the lab:

- instance name: `pangolin-lan`

Network model:

```text
eth0 -> macvlan on parent interface col0
```

Result:

- guest LAN IP: `192.168.1.106`
- gateway: `192.168.1.1`

### 4. Enable Docker-friendly nesting settings

The guest needed the standard nested-container settings:

- `security.nesting=true`
- `security.syscalls.intercept.mknod=true`
- `security.syscalls.intercept.setxattr=true`

Without these, Docker inside the nested guest is likely to fail or behave inconsistently.

### 5. Install Docker inside the nested guest

Validation used:

```text
docker run hello-world
```

This succeeded before Pangolin was staged, which confirmed the guest was ready for real workloads.

### 6. Stage the Pangolin stack inside the guest

Stack path inside the guest:

- `/opt/pangolin`

The staged stack mirrors the known-good local DNS-01 pattern:

- `pangolin`
- `gerbil`
- `traefik`

Key characteristics:

- Traefik shares Gerbil's network namespace
- Gerbil uses the specific Pangolin API endpoints
- Traefik uses DNS-01 with Cloudflare
- the wildcard cert request is scoped correctly to:
  - `pg.androidrobot.cloud`
  - `*.pg.androidrobot.cloud`

### 7. Validate the nested Pangolin stack

Working result:

- Pangolin healthy
- Traefik up
- Gerbil up
- direct HTTPS validation against `192.168.1.106` returns `HTTP/2 200`
- Traefik serves a real wildcard Let's Encrypt certificate for:
  - `pg.androidrobot.cloud`
  - `*.pg.androidrobot.cloud`

### 8. Add Newt as a separate compose project

Path inside the guest:

- `/opt/newt/docker-compose.yml`

In the validated lab:

- Newt connects successfully to the nested Pangolin instance
- websocket and tunnel setup complete successfully

## Current Working Services

Inside `pangolin-lan`:

- Pangolin stack:
  - `/opt/pangolin`
- Newt stack:
  - `/opt/newt`

Current service intent:

- keep this as a clean parallel lab
- do not repoint the main DNS at it
- use it to test Pangolin in a nested Incus + Docker + LAN-IP model

## Validation Checklist

### Parent VM validation

You should be able to confirm:

- the Colima VM has its own LAN IP
- Incus is healthy
- the nested guest exists

### Nested guest validation

You should be able to confirm:

- guest has its own `192.168.1.x` address
- default route points to the LAN router
- Docker works
- Pangolin stack starts
- direct HTTPS to the guest works

### Certificate validation

Expected end state:

- `HTTP/2 200`
- certificate CN `pg.androidrobot.cloud`
- SAN includes `*.pg.androidrobot.cloud`

## Lessons Learned

### 1. The VM having a LAN IP is not enough

The Colima VM being bridged to the LAN only proves the parent VM is reachable.

It does not prove Pangolin itself has a first-class LAN identity.

### 2. Test networking before Pangolin

The disposable nested guest test was worth it.

It separated:

- bridge/macvlan problems
- DHCP problems
- Docker problems
- Pangolin problems

### 3. `macvlan` solved the real problem faster than `br0`

We did not need to create an experimental `br0` inside the Colima VM to prove the concept.

`macvlan` on the VM's LAN-facing NIC was enough to give the nested guest its own LAN IP.

### 4. Parent-to-child isolation is expected

This is the big one.

With `macvlan`:

- Mac / LAN clients can talk to the nested guest
- the parent Colima VM cannot

If you forget that, you will waste time debugging a non-bug.

### 5. Keep the first nested Pangolin guest as a lab

The safest pattern is:

- get the guest working
- reserve or stabilize the DHCP lease
- keep it parallel
- only then decide whether it should ever replace another install

### 6. Pangolin config bugs and network bugs look similar at first

The earlier DNS-01 work still mattered here.

Even with the right nested network model, Pangolin would still fail if:

- the wildcard domain pair is wrong
- Gerbil endpoints are wrong
- ACME propagation checks use the wrong resolver path

Networking success did not remove the need for correct Traefik and Pangolin scaffolding.

## Known Gotchas

### `macvlan` host isolation

The parent Colima VM cannot directly reach the nested Pangolin guest.

Plan your validation from the Mac host or other LAN clients, not only from inside the VM.

### DHCP drift

The nested guest will initially take whatever LAN DHCP lease it gets.

If you want reproducibility, reserve the MAC on the router.

### Fresh Pangolin state

This lab was staged as a fresh instance, not a copied live database clone.

That means:

- new setup token
- clean application state
- suitable for build validation, not for claiming it is a stateful clone

### Gerbil bandwidth-report noise

If no real site / Newt resource topology is configured yet, Gerbil may log `400 Bad Request` for bandwidth reporting.

That is expected in an incomplete lab.

## Recommended Next Improvements

### Keep as-is

- nested guest on `192.168.1.106`
- separate Newt compose
- direct LAN testing

### Improve next

- snapshot `pangolin-lan`
- give the lab a dedicated hostname instead of reusing the main one during direct tests
- move inline secrets to `.env`
- pin the floating `traefik:v3.6` tag
- decide whether the lab should stay on Enterprise or align to the exact production edition

## Current Verdict

This build pattern is successful.

It proves all of the following at once:

- nested Incus inside bridged Colima can work
- the nested guest can have its own LAN IP
- Docker can run inside that nested guest
- Pangolin can run there successfully
- Newt can connect there successfully

For the original question, this is the answer:

```text
Yes — Pangolin can have its own LAN IP in this design.
```
