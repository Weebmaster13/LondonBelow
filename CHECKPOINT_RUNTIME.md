# Checkpoint Runtime

`CheckpointRuntime` owns reusable checkpoint schemas.

Checkpoints must not save unsafe temporary pressure, horror pacing state, Monster AI state, client-only state, Workspace references, final cutscene state, Lighting, Audio, or UI commands.

## Rules

- Server owns checkpoint truth.
- Invalid checkpoint IDs reject.
- Unknown profiles reject through `SaveCoordinator`.
- Unsafe checkpoint state rejects.
- Checkpoint history is bounded per profile.

## Future Work

Future Chapter systems may define real checkpoint schemas. Future DataStore work may persist safe checkpoints. This phase does not implement production persistence.