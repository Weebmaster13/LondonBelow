# Asset Execution Runtime Limits

Runtime limits match `AssetExecutionTypes.Limits` exactly:

- `MaxRuntimes = 160`
- `MaxRequests = 480`
- `MaxBoundaries = 320`
- `MaxAudits = 240`
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

Phase 92 validation rejects any drift in these names, values, or count before runtime health can pass. Diagnostics and snapshots expose copied limits only; mutating a returned diagnostics or snapshot table cannot mutate `AssetExecutionTypes.Limits`.
