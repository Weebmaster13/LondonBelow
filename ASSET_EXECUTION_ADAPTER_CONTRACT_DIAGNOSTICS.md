# Asset Execution Adapter Contract Diagnostics

Adapter-contract diagnostics are health-only and exposed through `assetExecutionRuntime`.

Diagnostics and snapshots expose:

- `adapterContract.declarationCount`
- `adapterContract.declarations`
- `adapterContract.order`
- `adapterContract.fields`

All returned values are isolated deep copies.

LowerCamelCase Phase 97 posture keys:

- `assetExecutionAdapterContractPosture`
- `assetExecutionAdapterContractValidationPosture`
- `assetExecutionAdapterContractIsolationPosture`
- `assetExecutionAdapterContractBoundaryPosture`
- `assetExecutionAdapterContractDocumentationPosture`
- `assetExecutionAdapterContractSerializationPosture`
- `assetExecutionAdapterContractLifecyclePosture`
- `assetExecutionAdapterContractAuthorityPosture`
- `assetExecutionAdapterContractOperationPosture`
- `assetExecutionAdapterContractGovernancePosture`
- `assetExecutionAdapterContractBootstrapPosture`

These keys report copied metadata posture only. They do not expose adapter runtime handles, adapter providers, adapter registries, adapter activation, routes, dispatch targets, queues, scheduler handles, orchestration handles, gameplay state, Presentation state, Save state, or Chapter content.

## Phase 98 Hardening Posture

Diagnostics and snapshots now also expose these lowerCamelCase health-only posture keys:

- `assetExecutionAdapterContractHardeningPosture`
- `assetExecutionAdapterContractValidationHardeningPosture`
- `assetExecutionAdapterContractSerializationHardeningPosture`
- `assetExecutionAdapterContractIsolationHardeningPosture`
- `assetExecutionAdapterContractBoundaryHardeningPosture`
- `assetExecutionAdapterContractDocumentationHardeningPosture`
- `assetExecutionAdapterContractGovernanceHardeningPosture`
- `assetExecutionAdapterContractBootstrapHardeningPosture`
- `assetExecutionAdapterContractIdentityHardeningPosture`
- `assetExecutionAdapterContractLifecycleHardeningPosture`
- `assetExecutionAdapterContractAuthorityHardeningPosture`
- `assetExecutionAdapterContractOperationHardeningPosture`

All adapter-contract diagnostics and snapshots remain isolated deep copies. They expose health and copied metadata only.
