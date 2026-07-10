# Asset Governance Certification Inspection Runtime Limits

`Types.Limits` defines the authoritative Phase 70 limits:

- `MaxInspections = 80`
- `MaxObservations = 700`
- `MaxFindings = 520`
- `MaxAudits = 320`
- `MaxValidationFailures = 260`
- `MaxSnapshotHistory = 70`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 520`
- `MaxStringLength = 300`
- `MaxTags = 36`
- `MaxEvidence = 48`
- `MaxAuditFindings = 48`
- `MaxInspectionChildren = 240`

These limits bound copied metadata only. They do not schedule work, inspect mutable state, authorize execution, repair runtimes, persist data, network, mutate upstream state, or execute gameplay.

Integration-readiness declarations are static `Types` metadata and do not add new mutable storage limits.

Decision-readiness declarations are static `Types` metadata and do not add new mutable storage limits. Phase 71 keeps `Types.Limits` unchanged.

Phase 72 keeps `Types.Limits` unchanged. Decision-readiness hardening expands validation and self-check coverage only; it adds no mutable storage and no runtime execution surface.
