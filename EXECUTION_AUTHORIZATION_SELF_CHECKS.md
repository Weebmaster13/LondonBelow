# Execution Authorization Self-Checks

Phase 149 adds deterministic self-check definitions through
`ExecutionAuthorizationCoordinator.runSelfChecks()`.

Coverage includes:

- empty policy set
- single policy
- multiple policies
- duplicate policy rejection
- duplicate rule rejection
- missing planning publication rejection
- invalid planning publication rejection
- planning version drift rejection
- blocked runtime truth drift rejection
- invalid policy classification rejection
- invalid rule classification rejection
- immutable publication copy isolation
- deterministic evaluation
- deterministic serialization
- snapshot stability
- diagnostics stability
- audit ordering
- no execution posture
- shutdown cleanup
- regression compatibility with Phases 140 through 148

Runtime execution still requires an authoritative Roblox/Luau environment.
