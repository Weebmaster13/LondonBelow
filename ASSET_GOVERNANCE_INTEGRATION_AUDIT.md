# Asset Governance Integration Audit

Governance integration audit records describe review evidence for the read-only asset governance chain.

`GovernanceIntegrationAudit` fields:

- `auditId`
- `chainId`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`

Accepted `auditKind` values:

- `ChainAudit`
- `ProviderAudit`
- `ReferenceAudit`
- `ProductionAudit`
- `FutureAudit`

Accepted `status` values:

- `Passed`
- `Failed`
- `Warning`
- `Deferred`
- `Blocked`

Audits do not approve runtime execution. They do not load assets, execute assets, repair upstream data, mutate upstream runtimes, grant client authority, create remotes, persist data, call HTTP or messaging services, collect analytics, send telemetry, or add Chapter content.
