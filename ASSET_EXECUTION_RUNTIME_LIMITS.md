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

Phase 93 does not change runtime limits. Integration-readiness declarations reuse the same payload, evidence, tag, string, diagnostics, and snapshot bounds and expose copied limit data only.

Phase 94 does not change runtime limits. Hardening self-checks verify that every exposed limit remains a deep copy and that integration-readiness evidence, tags, metadata, declaration arrays, and order tables stay within the certified Phase 92 limits.

Phase 95 does not change runtime limits. Adapter-readiness declarations reuse the exact same payload, evidence, tag, string, diagnostics, and snapshot bounds defined in `AssetExecutionTypes.Limits`.

Phase 96 does not change runtime limits. Hardening self-checks continue to prove runtime limits are copied through diagnostics and snapshots and cannot be mutated through returned tables.

Phase 97 does not change runtime limits. Adapter-contract declarations reuse the same certified payload, evidence, tag, string, diagnostics, and snapshot bounds.
## Phase 98 Adapter Contract Limit Posture

Phase 98 does not change `Types.Limits`. Adapter-contract hardening reuses the certified runtime limits for payload depth, payload node count, string length, evidence length, tag length, child references, validation failures, and snapshot history.

Runtime-limit drift remains a validation and self-check failure.

## Phase 99 Adapter Contract Integration Limit Posture

Phase 99 does not change `Types.Limits`. Adapter-contract integration readiness reuses the certified runtime limits for payload depth, payload node count, string length, evidence length, tag length, validation failures, and snapshot history.
