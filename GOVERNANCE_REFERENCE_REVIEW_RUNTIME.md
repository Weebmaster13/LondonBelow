# Governance Reference Review Runtime

`GovernanceReferenceReview` records describe metadata-only reference readiness between two runtimes in the asset governance chain.

Fields:

- `reviewId`
- `chainId`
- `sourceRuntimeName`
- `targetRuntimeName`
- `referenceKind`
- `referenceStatus`
- `summary`
- `tags`
- `metadata`

Accepted `referenceKind` values:

- `ReadinessReference`
- `DesignContractReference`
- `AssetReference`
- `UsagePlanReference`
- `ChecklistReference`
- `ApprovalReference`
- `PermitReference`
- `GateReference`
- `RuntimeOrderReference`
- `FutureReference`

Accepted `referenceStatus` values:

- `Present`
- `Missing`
- `Passed`
- `Blocked`
- `NeedsReview`
- `Deferred`

Reference reviews do not perform cross-runtime repair, upstream mutation, asset execution, client authority, remotes, persistence, HTTP, messaging, analytics, telemetry, or Chapter content.
