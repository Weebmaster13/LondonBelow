# Asset Execution Design Contract Runtime Limits

- `MaxReviews = 900`
- `MaxRisks = 1200`
- `MaxRequirements = 1200`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxReviewChildren = 220`

Limits protect the design contract runtime from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
