# Phase 189 - PlayerGui Remount

The rendering controller watches the local player for a replacement PlayerGui and disconnects its watcher on destruction. The renderer rejects remount while busy or shut down, validates the target class, moves only the runtime-owned root, updates interaction mount ownership, and records remount diagnostics.

## Ownership

Phase 189 owns safe recovery of its active local GUI root when PlayerGui is replaced.

## Non-Ownership

It does not control respawn, character creation, another player, or unrelated PlayerGui descendants.

## Certification Boundary

Real respawn and replacement recovery must pass Studio tests.
