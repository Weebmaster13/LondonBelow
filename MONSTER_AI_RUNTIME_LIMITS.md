# Monster AI Runtime Limits

Monster AI Execution Foundation is bounded by design.

## Limits

- Registered monsters: `MaxMonsters`.
- Recent intent records: `MaxIntentHistory`.
- Replay-protection intent IDs: `MaxSeenIntentIds`.
- Recent execution records: `MaxExecutionRecords`.
- Validation failures: `MaxValidationFailures`.
- Snapshot history: `MaxSnapshotHistory`.
- Payload depth: `MaxContextDepth`.
- Payload node count: `MaxContextNodes`.
- Payload string length: `MaxContextStringLength`.
- Default intent expiration: `DefaultExpirationSeconds`.

## Cleanup

`MonsterAIService.shutdown` clears registry records, intent history, execution history, validation failures, snapshot history, replay-protection IDs, monster states, and counters.

## Dry-Run Boundary

Runtime mode must remain `DryRunOnly`. The foundation records what future execution would do, but it does not execute movement, pathfinding, attacks, damage, animation, Workspace mutation, Lighting, Audio, UI, remotes, final scares, or Chapter content.