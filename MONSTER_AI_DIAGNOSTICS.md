# Monster AI Diagnostics

Monster AI diagnostics are exposed through `MonsterAIService.inspect` and the `monsterAIExecution` snapshot provider.

## Diagnostics Expose

- Initialization and started state.
- Runtime mode, which must remain `DryRunOnly`.
- Registered monster count.
- Recent approved/rejected intent records.
- Recent dry-run execution records.
- Validation failure count and recent sanitized validation failures.
- Replay-protection intent ID count.
- Dry-run count.
- Observation emission count.
- Runtime limits.
- Last self-check results.
- Health state.

## Snapshot Guarantees

Snapshots are deep-copied and isolated. Mutating a returned snapshot must not mutate internal Monster AI state.

## Diagnostics Isolation

Diagnostics use copied state and sanitized validation payloads. Mutating diagnostics output must not mutate internal runtime state, and rejected unsafe payloads must not preserve raw functions, threads, userdata, cycles, or future Roblox Instances.

## Debug Boundary

Diagnostics are read-only. They must never become controls for movement, pathfinding, Workspace mutation, attacks, animation, audio, lighting, UI, or client presentation.