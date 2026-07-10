# Governance Chain Runtime

`GovernanceChain` records define a named read-only integration chain.

Required fields are `chainId`, `chainKind`, and `chainStatus`. Optional `runtimeNodeIds`, `referenceReviewIds`, `auditIds`, `tags`, `metadata`, and `schemaType` remain bounded metadata.

Governance chains do not resolve upstream records, repair upstream data, load assets, execute assets, grant permissions, or mutate other runtimes.
