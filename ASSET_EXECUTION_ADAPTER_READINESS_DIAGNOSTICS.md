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

These keys report copied metadata posture only. They do not expose live adapters, asset-operation providers, routes, dispatch targets, queues, schedulers, orchestration handles, callbacks, listeners, services, modules, remotes, client authority, gameplay state, Presentation state, Save state, or Chapter content.

