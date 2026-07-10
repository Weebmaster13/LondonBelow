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
