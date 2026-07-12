# Asset Execution Adapter Readiness

Phase 95 adds adapter-readiness declarations to the existing `AssetExecutionRuntime`.

Provider: `assetExecutionRuntime`

Snapshot provider: `assetExecutionRuntime`

Coordinator: `AssetExecutionCoordinator`

Declaration count: 38

Adapter readiness is static copied metadata only. It describes what a future, separately governed adapter layer must keep compatible with the certified Asset Execution Runtime. It does not create an adapter runtime, adapter provider, adapter coordinator, adapter registry, adapter callback, adapter listener, adapter service, adapter module, route, dispatcher, queue, scheduler, orchestration layer, or asset-operation API.

Fields:

- `readinessId`
- `compatibilityId`
- `adapterReadinessDeclarationId`
- `readinessKind`
- `readinessStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `coordinatorName`
- `diagnosticsProviderName`
- `bootstrapDependencyName`
- `engineGovernanceSnapshotProviderName`
- `documentationReference`
- `executionRuntimeName`
- `executionProviderName`
- `executionSnapshotProviderName`
- `executionCoordinatorName`
- `futureAdapterRuntimeName`
- `futureAdapterProviderName`
- `futureAdapterSnapshotProviderName`
- `futureAdapterCoordinatorName`
- `adapterKind`
- `adapterAuthorityKind`
- `adapterBoundaryKind`
- `assetOperationBoundaryKind`
- `lifecycleBoundaryKind`
- `required`
- `evidence`
- `tags`
- `metadata`

Future adapter identities are explicitly absent through copied metadata:

- `AbsentFutureAdapterRuntime`
- `absentFutureAdapterProvider`
- `absentFutureAdapterSnapshotProvider`
- `AbsentFutureAdapterCoordinator`

These values are not registered providers. They are absence markers used by validation, diagnostics, snapshots, and self-checks.

