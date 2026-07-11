# Asset Execution Authorization Runtime Limits

Runtime limits match `AssetExecutionAuthorizationTypes.Limits` exactly:

- `MaxAuthorizations = 180`
- `MaxRequirements = 540`
- `MaxEvaluations = 540`
- `MaxBoundaries = 360`
- `MaxAudits = 260`
- `MaxValidationFailures = 220`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 520`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxEvidence = 56`
- `MaxChildReferences = 220`
- `MaxSummaryLength = 180`

Limits bound schema counts, copied payload size, validation failure history, snapshot history, child references, tags, evidence, and boundary summaries.

Phase 86 verifies that exposed limits are copied before diagnostics or snapshots return them. Mutating returned `runtimeLimits` cannot mutate `AssetExecutionAuthorizationTypes.Limits`.
