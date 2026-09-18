# Colima + Incus Bridged Sanity Test

Use this when you want a safe pre-flight check before trying Pangolin inside an Incus guest running inside a bridged Colima VM on macOS.

Script:

- [scripts/colima_incus_bridged_sanity.sh](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/scripts/colima_incus_bridged_sanity.sh)

Related:

- [PANGOLIN_NESTED_INCUS_LAN_LAB_BUILD.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/PANGOLIN_NESTED_INCUS_LAN_LAB_BUILD.md)
- [VM890_OFFLINE_CLONE_RUNBOOK.md](/Users/hustler2025/CodeWorkspace/Pangolin%20VPS%20Upgrade/VM890_OFFLINE_CLONE_RUNBOOK.md)

## What it checks

By default, the script is read-only and verifies:

- the Colima profile is running
- the expected macOS interface exists, such as `en0`
- the Colima VM has addresses
- Incus is available inside the VM
- Incus networks and the default profile are visible
- whether a Linux bridge like `br0` exists inside the Colima VM
- whether the safer `macvlan` approach should be considered before trying `br0`

Optional test mode can also:

- launch a disposable Debian Incus guest
- test the default Incus network path
- optionally attach that guest to an existing `br0`

## Safe usage

Read-only:

```bash
./scripts/colima_incus_bridged_sanity.sh
```

Disposable Incus guest on the default profile:

```bash
./scripts/colima_incus_bridged_sanity.sh --launch-test
```

Disposable Incus guest bridged to `br0`:

```bash
./scripts/colima_incus_bridged_sanity.sh --launch-test --use-bridge --bridge br0
```

## Why this is useful

It helps separate three very different cases:

1. The Colima VM itself has a usable bridged LAN IP.
2. Incus works normally inside that VM, but only on an Incus-managed private bridge.
3. Nested Incus instances can also attach to an existing Linux bridge like `br0`.

That distinction matters because `Colima bridged mode` and `Incus bridged NICs` are related, but not the same thing.

## What the safe live test proved

The current documented lab moved past theory and proved the following:

```text
Colima VM bridged to LAN             -> yes
Nested Incus on private incusbr0     -> yes
Nested Incus guest with own LAN IP   -> yes, via macvlan on col0
Need for br0 to prove the concept    -> no
```

The disposable nested guest using:

```text
nictype=macvlan,parent=col0
```

received its own LAN DHCP lease and was reachable from the Mac host and other LAN clients.

That became the basis for the working `pangolin-lan` lab.

See also:

- `/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/PANGOLIN_NESTED_INCUS_LAN_LAB_BUILD.md`

## Gotcha

Even if the Colima VM is bridged to your LAN, that does not automatically prove that nested Incus guests will cleanly get first-class LAN DHCP through a Linux `br0` created inside the VM. Treat that last step as experimental until the script proves it.

There is also a more practical gotcha:

```text
macvlan guest reachable from Mac/LAN clients   -> yes
macvlan guest reachable from parent Colima VM  -> no
```

That is expected and should be part of the test plan.
