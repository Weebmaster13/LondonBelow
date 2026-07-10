# Asset Governance Certification Audit

`GovernanceCertificationAudit` records describe review evidence for certification metadata.

Fields:

- `auditId`
- `certificationId`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`

Audits do not authorize execution, repair data, mutate upstream runtimes, create remotes, persist data, or add Chapter content.

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

`findings` is a bounded id array with `MaxAuditFindings = 40`. `tags` is bounded by `MaxTags = 32`. `metadata` must be serializable and cannot contain runtime handles, asset handles, service handles, callbacks, listeners, execution adapters, repair markers, authorization markers, or execution markers.
