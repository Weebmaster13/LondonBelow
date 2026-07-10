# Asset Governance Integration Runtime Limits

These limits must match `AssetGovernanceIntegrationTypes.Limits` exactly.

- `MaxChains = 20`
- `MaxRuntimeNodes = 200`
- `MaxReferenceReviews = 500`
- `MaxAudits = 300`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxChainChildren = 120`

Limits protect the read-only integration runtime from unbounded metadata and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
