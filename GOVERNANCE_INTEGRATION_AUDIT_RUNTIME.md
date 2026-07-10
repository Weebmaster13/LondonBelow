# Governance Integration Audit Runtime

`GovernanceIntegrationAudit` records describe audit evidence for the Asset Governance Integration runtime.

Required fields are `auditId`, `chainId`, `auditKind`, `reviewer`, and `status`. Optional findings remain bounded metadata.

Integration audits do not approve asset execution, mutate upstream runtimes, create remotes, grant client authority, or add Chapter content.
