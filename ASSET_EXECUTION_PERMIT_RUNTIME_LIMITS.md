# Asset Execution Permit Runtime Limits

- `MaxPermits = 900`
- `MaxScopes = 1200`
- `MaxRestrictions = 1200`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxPermitChildren = 220`

Limits protect the permit runtime from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
