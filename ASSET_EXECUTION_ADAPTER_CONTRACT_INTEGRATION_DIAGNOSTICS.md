# Asset Execution Adapter Contract Integration Diagnostics

Adapter-contract integration diagnostics are health-only and exposed through `assetExecutionRuntime`.

Diagnostics and snapshots expose:

- `adapterContractIntegration.declarationCount`
- `adapterContractIntegration.declarations`
- `adapterContractIntegration.order`
- `adapterContractIntegration.fields`

All returned values are isolated deep copies.

LowerCamelCase Phase 99 posture keys:

- `assetExecutionAdapterContractIntegrationReadinessPosture`
- `assetExecutionAdapterContractIntegrationValidationPosture`
- `assetExecutionAdapterContractIntegrationIsolationPosture`
- `assetExecutionAdapterContractIntegrationBoundaryPosture`
- `assetExecutionAdapterContractIntegrationDocumentationPosture`
- `assetExecutionAdapterContractIntegrationSerializationPosture`
- `assetExecutionAdapterContractIntegrationLifecyclePosture`
- `assetExecutionAdapterContractIntegrationAuthorityPosture`
- `assetExecutionAdapterContractIntegrationOperationPosture`
- `assetExecutionAdapterContractIntegrationGovernancePosture`
- `assetExecutionAdapterContractIntegrationBootstrapPosture`

These keys report copied metadata posture only. They do not expose runtime handles, adapter handles, adapter implementations, execution APIs, registries, services, managers, loaders, factories, callbacks, listeners, routes, dispatchers, queues, schedulers, orchestrators, gameplay state, Presentation state, Save state, or Chapter state.

