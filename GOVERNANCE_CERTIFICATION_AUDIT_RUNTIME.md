# Governance Certification Audit Runtime

`GovernanceCertificationAudit` records describe audit evidence for certification reviews.

Fields:

- `auditId`
- `certificationId`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`

Audits remain bounded metadata and do not mutate upstream runtime state.

Accepted `auditKind` values:

- `CertificationAudit`
- `ProviderAudit`
- `DependencyAudit`
- `GovernanceAudit`
- `ProductionAudit`
- `FutureAudit`

Accepted `status` values:

- `Passed`
- `Failed`
- `Warning`
- `Deferred`
- `Blocked`

`certificationId` must reference an already registered `GovernanceCertification`. `reviewer` is required and must be a valid id. `findings` is a bounded id array with `MaxAuditFindings = 40`. Audit records cannot authorize execution, repair governance data, or mutate upstream state.
