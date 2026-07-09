# Asset Execution Implementation Contract Runtime Limits

- `MaxContracts = 900`
- `MaxResponsibilities = 1200`
- `MaxBoundaries = 1200`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxContractChildren = 220`

Limits protect the implementation contract runtime from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
