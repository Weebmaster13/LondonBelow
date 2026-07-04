# Asset Runtime Gate Runtime Limits

- `MaxGates = 900`
- `MaxChecks = 1200`
- `MaxBlocks = 1200`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxGateChildren = 220`

Limits protect the gate runtime from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
