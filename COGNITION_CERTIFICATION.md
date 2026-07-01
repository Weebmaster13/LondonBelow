# Cognition Certification

Phase 16 includes deterministic self-checks for the Living Cognition substrate.

## Covered Scenarios

- Malformed observation rejection.
- Duplicate registration rejection.
- Invalid confidence rejection.
- Invalid timestamp rejection.
- Execution-like field rejection.
- Workspace/Instance-style reference rejection.
- Cyclic serialization rejection.
- Unsafe runtime value rejection.
- Oversized payload rejection.
- Stale evidence decay.
- Contradictory evidence lowering confidence.
- Deterministic hypothesis ranking.
- Thought decay.
- Thought merge.
- Thought split.
- Invalid thought transition rejection.
- Belief reinforcement bounds.
- Belief contradiction bounds.
- Diagnostics read-only behavior.
- Snapshot isolation.
- Serialization integrity and isolation.
- Shutdown cleanup.
- No remotes, Workspace mutation, Lighting mutation, Audio playback, pathfinding, navigation, gameplay execution, Monster AI execution, or client authority.

## Certification Boundary

Certification proves the substrate behaves correctly as cognition. It does not certify Monster AI, gameplay, presentation, Chapter content, final horror behavior, movement, pathfinding, attacks, animation, NPCs, remotes, or Workspace execution.

## Runtime Safety

Self-checks are destructive because they clear the cognition state used for certification. They may run before startup only; the coordinator rejects self-check execution after the runtime starts.