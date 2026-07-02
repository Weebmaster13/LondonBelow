# Physical Self-Checks

`PhysicalSelfChecks` certifies Phase 21 behavior with deterministic scenarios.

## Proofs

Self-checks prove:

- malformed object rejects
- duplicate object rejects
- invalid object type rejects
- valid object registers
- valid ownership assigns
- malformed ownership rejects
- unknown ownership rejects
- valid reservation creates
- duplicate reservation rejects
- unknown object reservation rejects
- reservation release works
- unknown reservation release rejects
- invalid ownership rejects
- valid state updates
- malformed state rejects
- valid lifecycle updates
- malformed lifecycle rejects
- valid transform updates
- malformed transform rejects
- unsafe payload rejects
- unsafe metadata rejects
- unsafe tags reject
- Roblox Instance rejects
- cycle rejects
- unsafe runtime values reject
- oversized payload rejects
- oversized string rejects
- deep payload rejects
- serialization safety
- snapshot isolation
- diagnostics read-only
- bounded histories
- removing an object clears ownership, reservations, lifecycle, state, and transform records
- shutdown cleanup

## Non-Ownership Proofs

Self-checks also assert no gameplay execution, movement, animation, physics, pathfinding, Workspace mutation, client authority, remotes, UI, Audio, Lighting, Monster AI ownership, Narrative ownership, Save ownership, Horror ownership, Horror pacing ownership, or Chapter content.
