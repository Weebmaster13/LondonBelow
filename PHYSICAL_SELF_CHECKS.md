# Physical Self-Checks

`PhysicalSelfChecks` certifies Phase 21 behavior with deterministic scenarios.

## Proofs

Self-checks prove:

- malformed object rejects
- duplicate object rejects
- duplicate reservation rejects
- invalid ownership rejects
- unsafe payload rejects
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
- shutdown cleanup

## Non-Ownership Proofs

Self-checks also assert no gameplay execution, movement, animation, physics, Workspace mutation, client authority, remotes, Monster AI ownership, Narrative ownership, Save ownership, or Horror ownership.
