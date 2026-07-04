# Asset Approval Ledger Runtime Limits

- `MaxApprovals = 900`
- `MaxConditions = 1200`
- `MaxRevocations = 700`
- `MaxAudits = 500`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxApprovalChildren = 220`

Limits protect the ledger from unbounded schema growth and diagnostic memory growth. Exceeding a limit rejects the attempted schema before mutation.
