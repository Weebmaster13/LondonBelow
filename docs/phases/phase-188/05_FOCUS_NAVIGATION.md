# Phase 188 - Focus Navigation

Focusable controls receive deterministic `SelectionOrder`. Ties resolve by stable node identity. Before reconciliation, the focus manager captures the selected runtime-owned node. After replacement, it restores that node when still enabled; otherwise it chooses the first enabled control. Unmount clears selection only when it belongs to the runtime tree.

This protects keyboard and gamepad users from being dropped at every GUI revision while avoiding mutation of unrelated PlayerGui interfaces.

## Ownership

Phase 188 owns focus order and restoration for runtime-owned controls.

## Non-Ownership

It does not own focus inside unrelated Roblox CoreGui or independently authored PlayerGui trees.

## Certification Boundary

Focus restoration, fallback, and isolation require Studio evidence.
