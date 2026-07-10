# Governance Reference Review Runtime

`GovernanceReferenceReview` records describe metadata-only reference readiness between two runtimes in the asset governance chain.

Required fields are `reviewId`, `chainId`, `sourceRuntimeName`, `targetRuntimeName`, `referenceKind`, `referenceStatus`, and `summary`.

Reference reviews do not perform cross-runtime repair, upstream mutation, asset execution, client authority, remotes, or Chapter content.
