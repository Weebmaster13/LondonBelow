# Governance Chain Runtime

`GovernanceChain` records define a named read-only integration chain.

Fields:

- `chainId`
- `chainKind`
- `chainStatus`
- `runtimeNodeIds`
- `referenceReviewIds`
- `auditIds`
- `tags`
- `metadata`

Accepted `chainKind` values:

- `CertifiedAssetGovernanceChain`
- `RuntimeProviderChain`
- `ReferenceReadinessChain`
- `FutureIntegrationChain`

Accepted `chainStatus` values:

- `Healthy`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

Governance chains do not resolve upstream records, repair upstream data, load assets, execute assets, grant permissions, mutate other runtimes, create remotes, or add Chapter content.
