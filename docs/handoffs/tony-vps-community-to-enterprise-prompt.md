Use this repo as the source of truth:

`/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade`

Task:

`tony-vps-community-to-enterprise-v1`

Start with:

`/Users/hustler2025/CodeWorkspace/Pangolin VPS Upgrade/docs/handoffs/tony-vps-community-to-enterprise.md`

Requirements:

- Read the handoff first and follow it exactly.
- Treat `revelectronics@tony_vps` as the target host.
- Treat `/home/revelectronics/docker/pangolin` as the Pangolin stack path.
- Treat `https://pangolin.pang.revelectronics.uk` as the canonical dashboard URL.
- Do not assume this host matches `vm890`; prove the live facts first.
- Reuse the repo helper scripts where safe, even if their filenames still mention `vm890`.
- Stage the work in this exact order:
  1. read-only fact gathering
  2. host-specific runtime/spec bootstrap
  3. read-only audit
  4. latest stable Community upgrade with backups before each hop
  5. same-version Enterprise conversion with a fresh backup
  6. post-conversion health verification
- Preserve all rollback data.
- Do not stop or modify unrelated containers outside this Pangolin stack.
- Stop on mismatch.
- Report only in the handoff's required final report format.
