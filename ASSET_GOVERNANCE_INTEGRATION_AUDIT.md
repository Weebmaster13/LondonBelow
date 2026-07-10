# Asset Governance Integration Audit

Governance integration audit records describe review evidence for the read-only asset governance chain.

Audit records require `auditId`, `chainId`, `auditKind`, `reviewer`, and `status`. Optional `findings`, `tags`, `metadata`, and `schemaType` remain bounded, serializable metadata.

Audits do not approve runtime execution by themselves. They do not load assets, execute assets, repair upstream data, mutate upstream runtimes, grant client authority, create remotes, or add Chapter content.
