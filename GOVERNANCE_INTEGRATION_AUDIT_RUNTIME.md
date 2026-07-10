# Governance Integration Audit Runtime

`GovernanceIntegrationAudit` records describe audit evidence for the Asset Governance Integration Runtime.

Fields:

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

Integration audits do not approve asset execution, mutate upstream runtimes, repair records, create remotes, grant client authority, persist data, call HTTP or messaging services, collect analytics, send telemetry, or add Chapter content.
