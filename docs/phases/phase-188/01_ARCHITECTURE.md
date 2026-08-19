# Phase 188 - Architecture

The subsystem is split into interaction types and limits, exact accessibility metadata validation, focus capture/restoration, and the interaction runtime. Phase 187 validation invokes accessibility validation before Instance creation. Rendering captures focus before root replacement, commits the new tree, registers it, then reconciles controls. Unmount disconnects controls before destroying Instances.

Public API: `configure`, `registerAction`, `unregisterAction`, `setAnnouncer`, `captureFocus`, `reconcile`, `unmount`, `inspect`, `getSnapshot`, and `shutdown`.

## Ownership

Phase 188 owns the client presentation interaction boundary and its deterministic lifecycle.

## Non-Ownership

It does not fetch contracts, author actions, create remotes, or convert callbacks into trusted server facts.

## Certification Boundary

Architecture and static checks cannot substitute for Roblox input execution.
