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
- `MaxChildReferences = 260`
- `MaxSummaryLength = 180`

These limits bound metadata only and do not create runtime work queues.
