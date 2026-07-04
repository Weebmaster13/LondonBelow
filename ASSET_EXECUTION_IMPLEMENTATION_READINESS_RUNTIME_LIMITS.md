# Asset Execution Implementation Readiness Runtime Limits

- `MaxReadinessRecords = 900`
- `MaxChecklists = 1200`
- `MaxGaps = 1200`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxReadinessChildren = 220`

Limits protect the implementation readiness runtime from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
