# Asset Governance Certification Runtime Limits

- `MaxCertifications = 60`
- `MaxRequirements = 600`
- `MaxResults = 600`
- `MaxAudits = 300`
- `MaxValidationFailures = 240`
- `MaxSnapshotHistory = 60`
- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`
- `MaxTags = 32`
- `MaxAuditFindings = 40`
- `MaxResultEvidence = 40`
- `MaxCertificationChildren = 180`

Limits protect certification metadata and diagnostics from unbounded growth. Exceeding a limit rejects the attempted schema before mutation.

Phase 62 self-checks verify every identifier and value above against `Types.Limits`. Documentation must follow the implementation if future limits change.
