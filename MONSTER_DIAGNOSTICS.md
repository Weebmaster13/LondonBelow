# Monster Diagnostics

Monster Intelligence must remain inspectable.

## Diagnostics Track

- Active monster records.
- Memory counts.
- Knowledge counts.
- Interest counts.
- Shared claims.
- Shared facts.
- Decision reasons.
- Validation failures.
- Self-check results.
- Runtime health.

## Snapshot Provider

`monsterIntelligence` is registered with `SnapshotManager`.

## Sampler

`MonsterIntelligence` is registered with `Diagnostics`.

## Self-Checks

Self-checks verify memory decay, knowledge transitions, duplicate monster rejection, duplicate claim rejection, bounded memory, bounded diagnostics, unsafe request rejection, server authority, simulation correctness, no Workspace mutation, no navigation, and no client authority.

## Production Boundary

Diagnostics must never expose a path to mutate Workspace, Lighting, Sound, NPC state, or client UI.
