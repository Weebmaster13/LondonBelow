# Execution Self-Checks

`ExecutionSelfChecks` provides deterministic certification for Phase 20.

## Proofs

Self-checks prove:

- malformed execution rejects
- duplicate execution rejects
- duplicate approvals reject
- missing approvals reject
- missing dependencies reject
- expired execution rejects
- unsupported execution rejects
- unsafe payload rejects
- Workspace payload rejects
- Instance payload rejects
- cycle rejects
- unsafe runtime values reject
- oversized payloads reject
- oversized strings reject
- deep payloads reject
- snapshots are isolated
- diagnostics are read-only
- histories are bounded
- queue is bounded
- audit is bounded
- serialization is safe
- shutdown cleanup clears state

## Non-Ownership Proofs

Self-checks also assert no gameplay execution, movement, damage, animation, pathfinding, doors, UI, audio, lighting, presentation, remotes, Workspace mutation, client authority, Chapter content, Monster AI ownership, Narrative ownership, Save ownership, or horror pacing ownership.
