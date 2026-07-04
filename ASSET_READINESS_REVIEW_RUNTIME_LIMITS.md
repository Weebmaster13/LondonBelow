# Asset Readiness Review Runtime Limits

- `MaxChecklists = 900`
- `MaxFindings = 1200`
- `MaxGates = 1200`
- `MaxDecisions = 700`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxChecklistChildren = 220`

Limits protect the runtime from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
