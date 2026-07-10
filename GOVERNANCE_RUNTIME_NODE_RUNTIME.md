# Governance Runtime Node Runtime

`GovernanceRuntimeNode` records describe one certified runtime position inside a governance chain.

Fields:

- `nodeId`
- `chainId`
- `runtimeName`
- `providerName`
- `coordinatorName`
- `expectedOrder`
- `required`
- `nodeStatus`
- `tags`
- `metadata`

Accepted runtime names and providers:

- `AssetManifest` uses `assetManifestRuntime`
- `AssetUsagePlan` uses `assetUsagePlanRuntime`
- `AssetReadinessReview` uses `assetReadinessReviewRuntime`
- `AssetApprovalLedger` uses `assetApprovalLedgerRuntime`
- `AssetExecutionPermit` uses `assetExecutionPermitRuntime`
- `AssetRuntimeGate` uses `assetRuntimeGateRuntime`
- `AssetExecutionBoundaryReview` uses `assetExecutionBoundaryReviewRuntime`
- `AssetExecutionDesignContract` uses `assetExecutionDesignContractRuntime`
- `AssetExecutionImplementationReadiness` uses `assetExecutionImplementationReadinessRuntime`
- `AssetExecutionImplementationContract` uses `assetExecutionImplementationContractRuntime`

Accepted `nodeStatus` values:

- `Ready`
- `Missing`
- `Blocked`
- `NeedsReview`
- `Deferred`

Runtime nodes validate provider, coordinator, and expected order consistency. They do not require or mutate upstream runtime records.
