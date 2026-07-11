# Asset Execution Governance Runtime Limits

Runtime limits are defined in `AssetExecutionGovernanceTypes.Limits`:

- `MaxGovernance = 140`
- `MaxRequirements = 540`
- `MaxAssessments = 720`
- `MaxFindings = 420`
- `MaxAudits = 320`
- `MaxValidationFailures = 260`
- `MaxSnapshotHistory = 70`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 560`
- `MaxStringLength = 300`
- `MaxTags = 36`
- `MaxEvidence = 64`
- `MaxIntegrationDeclarations = 10`
- `MaxAuthorizationReadinessDeclarations = 10`
- `MaxChildReferences = 260`
- `MaxSummaryLength = 180`

These limits bound metadata only and do not create runtime work queues.

Phase 83 adds only `MaxAuthorizationReadinessDeclarations = 10` for copied authorization-readiness metadata. Phase 84 keeps these limit values unchanged and hardens returned-copy isolation. Diagnostics and snapshots expose copied runtime limits only, and self-checks prove returned limit tables are isolated from runtime source tables.
