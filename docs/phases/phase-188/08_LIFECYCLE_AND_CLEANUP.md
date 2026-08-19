# Phase 188 - Lifecycle and Cleanup

Configure validates a local PlayerGui mount. Every reconcile disconnects previous control connections. Unmount disconnects controls and clears runtime-owned selection before Instances are destroyed. Shutdown repeats safe unmount, clears registered actions and announcer state, drops the mount target, and permanently rejects later work.

Diagnostics count disconnections so repeated revision replacement can be inspected for leaked bindings.

## Ownership

Phase 188 owns interaction connections, action registry cleanup, focus cleanup, and shutdown state.

## Non-Ownership

It does not destroy unrelated GUI trees or manage player/character server lifecycle.

## Certification Boundary

Unmount, shutdown, respawn, and repeated-revision cleanup must be exercised in Studio.
