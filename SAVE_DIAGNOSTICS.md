# Save Diagnostics

`SaveCoordinator.inspect` exposes read-only diagnostics for Phase 18.

## Exposes

- Lifecycle state.
- Profile count.
- Checkpoint count.
- Journal entry count.
- Memory Fragment count.
- Identity count.
- Replay state count.
- Validation failures.
- Runtime snapshots of each subsystem.
- Last self-check result.
- Health state.

Diagnostics are copied and must not become controls for UI, story, Monster AI, horror pacing, Workspace mutation, or client save truth. Mutating returned diagnostics must not mutate internal runtime state.