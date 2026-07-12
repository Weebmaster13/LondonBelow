# Asset Execution Adapter Readiness Diagnostics

Adapter-readiness diagnostics are health-only and exposed through `assetExecutionRuntime`.

Diagnostics and snapshots expose:

- `adapterReadiness.declarationCount`
- `adapterReadiness.declarations`
- `adapterReadiness.order`
- `adapterReadiness.fields`

All returned values are isolated deep copies.

LowerCamelCase Phase 95 posture keys:

- `assetExecutionAdapterReadinessPosture`
- `assetExecutionAdapterCompatibilityPosture`
- `assetExecutionAdapterIdentityPosture`
- `assetExecutionAdapterAuthorityPosture`
- `assetExecutionAdapterBoundaryPosture`
- `assetExecutionAdapterLifecyclePosture`
- `assetExecutionAdapterSerializationPosture`
- `assetExecutionAdapterIsolationPosture`
- `assetExecutionAdapterLimitPosture`
- `assetExecutionAdapterDocumentationPosture`
- `assetExecutionNoLiveAdapterPosture`
- `assetExecutionNoAssetOperationPosture`
- `assetExecutionAdapterHardeningPosture`
- `assetExecutionAdapterIdentityHardeningPosture`
- `assetExecutionAdapterBoundaryHardeningPosture`
- `assetExecutionAdapterDocumentationHardeningPosture`
- `assetExecutionAdapterSerializationHardeningPosture`
- `assetExecutionAdapterValidationHardeningPosture`
- `assetExecutionAdapterIsolationHardeningPosture`
- `assetExecutionAdapterLimitHardeningPosture`
- `assetExecutionAdapterGovernanceHardeningPosture`
- `assetExecutionAdapterBootstrapHardeningPosture`

These keys report copied metadata posture only. They do not expose live adapters, asset-operation providers, routes, dispatch targets, queues, schedulers, orchestration handles, callbacks, listeners, services, modules, remotes, client authority, gameplay state, Presentation state, Save state, or Chapter content.

Phase 96 adds production-hardening posture keys to diagnostics and snapshots. The keys are copied health strings only. They do not expose mutable references, runtime handles, adapter handles, route handles, dispatch handles, scheduler handles, or authority tokens.
