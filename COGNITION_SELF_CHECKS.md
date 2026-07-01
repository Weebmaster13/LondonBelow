# Cognition Self-Checks

Living Cognition self-checks are deterministic certification scenarios for the cognition runtime.

## Safety Boundary

Self-checks clear the cognition registry and state while running. Because of that, `LivingCognitionCoordinator.runSelfChecks` refuses to run after the runtime has started. Self-checks are for startup validation and development certification, not live production inspection.

## Proved Conditions

The self-check suite verifies:

- Malformed observations reject.
- Duplicate entity registration rejects.
- Invalid confidence rejects.
- Invalid timestamps reject.
- Execution-like payload fields reject.
- Workspace/Instance-style payload references reject through forbidden-field and serialization rules.
- Cyclic serialization rejects.
- Unsafe runtime values reject.
- Oversized payloads reject.
- Stale evidence decays.
- Contradiction lowers confidence safely.
- Hypothesis ranking is deterministic.
- Thought merge and split transitions are deterministic.
- Invalid thought transitions reject.
- Belief reinforcement stays bounded.
- Belief contradiction stays bounded.
- Diagnostics are read-only copies.
- Snapshots are isolated deep copies.
- Serialization output is isolated.
- Shutdown clears state.
- No remotes, Workspace mutation, Lighting mutation, Audio playback, pathfinding, navigation, gameplay execution, Monster AI execution, or client authority exists.

## Future Additions

Future self-checks may add replay fixtures, persistence schema checks, or integration checks with Monster Intelligence. They must remain cognition-only and must not create objects, remotes, assets, sounds, lighting effects, gameplay content, or NPCs.