# Execution Planning Self-Checks

Phase 148 adds deterministic runtime self-check coverage through
`ExecutionPlanningCoordinator.runSelfChecks()`.

The self-check matrix covers:

- provider identity
- blocked runtime truth preservation
- empty graph publication
- single node graph publication
- dependency chains
- branching graphs
- duplicate node rejection
- missing dependency rejection
- cycle detection
- illegal cross-authority ownership rejection
- dependency version mismatch rejection
- constraint-driven blocked eligibility
- deterministic node ordering
- deterministic rebuilds
- publication snapshot isolation
- diagnostics stability
- snapshot stability
- audit append behavior
- no execution posture
- shutdown cleanup

These checks are Roblox runtime self-checks. Static repository validation can
verify the modules compile, but Production Certification still requires the
authoritative runtime evidence path defined by earlier certification phases.
