# Monster AI Diagnostics

Monster AI diagnostics are exposed through `MonsterAIService.inspect` and the `monsterAIExecution` snapshot provider.

## Diagnostics Expose

- Initialization and started state.
- Runtime mode, which must remain `DryRunOnly`.
- Registered monster count.
- Recent approved/rejected intent records.
- Recent dry-run execution records.
- Validation failure count and recent validation failures.
- Dry-run count.
- Observation emission count.
- Runtime limits.
- Last self-check results.
- Health state.

## Snapshot Guarantees

Snapshots are deep-copied and isolated. Mutating a returned snapshot must not mutate internal Monster AI state.

## Debug Boundary

Diagnostics are read-only. They must never become controls for movement, pathfinding, Workspace mutation, attacks, animation, audio, lighting, UI, or client presentation.