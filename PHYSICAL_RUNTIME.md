# Physical Runtime

Phase 21 creates the Physical Runtime Foundation for London Engine.

This runtime is the server-authoritative source of truth for physical object schemas. It describes objects that future systems may use, but it does not manipulate Roblox Instances, move parts, simulate physics, run interactions, or execute gameplay.

## Owns

- physical object registration
- physical object identities
- physical object schemas
- ownership records
- reservations and execution lock schemas
- lifecycle state schemas
- transform schemas
- diagnostics
- snapshots
- serialization
- validation
- deterministic self-checks
- shutdown cleanup

## Does Not Own

Physical Runtime does not own Gameplay, Narrative, Monster AI, Living Cognition, Save, Journal, Identity, Replay, Gameplay Execution, horror pacing, Director logic, UI, Audio, Lighting, Animation, physics simulation, movement, navigation, pathfinding, combat, damage, NPC behavior, doors, drawers, interactables, puzzles, inventory, Chapter content, dialogue, story, cutscenes, Workspace mutation, client authority, remotes, or presentation.

## Runtime Entry Point

Use `PhysicalRuntimeCoordinator` for all public access:

- `registerObject(schema)`
- `removeObject(physicalObjectId)`
- `assignOwnership(physicalObjectId, ownerSystem)`
- `reserveObject(physicalObjectId, reservationId, ownerSystem)`
- `releaseReservation(reservationId)`
- `setObjectState(physicalObjectId, state)`
- `setLifecycle(physicalObjectId, lifecycleState)`
- `setTransform(physicalObjectId, transformSchema)`
- `inspect()`
- `getSnapshot()`
- `validate()`
- `runSelfChecks()`
- `shutdown()`

Every call remains schema-only.
