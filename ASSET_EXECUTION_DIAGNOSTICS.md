# Asset Execution Diagnostics

Diagnostics are health-only and exposed through `assetExecutionRuntime`.

Diagnostics include lifecycle state, validation health, schema counts, limit usage, copied runtime limits, provider posture, snapshot posture, documentation posture, Bootstrap dependency posture, Governance snapshot provider posture, copied schemas, recent validation failures, and latest self-check result.

LowerCamelCase posture keys include:

- `assetExecutionRuntimePosture`
- `assetExecutionRequestPosture`
- `assetExecutionBoundaryPosture`
- `assetExecutionAuditPosture`
- `assetExecutionIntegrationReadinessPosture`
- `assetExecutionCompatibilityPosture`
- `assetExecutionIntegrationHardeningPosture`
- `assetExecutionDeclarationExactnessPosture`
- `assetExecutionDeclarationOrderingPosture`
- `assetExecutionCompatibilityIdentityPosture`
- `assetExecutionOrderTablePosture`
- `assetExecutionMetadataExactnessPosture`
- `assetExecutionEvidenceExactnessPosture`
- `assetExecutionTagExactnessPosture`
- `assetExecutionAdapterContaminationPosture`
- `assetExecutionOperationContaminationPosture`
- `assetExecutionIntegrationLimitIsolationPosture`
- `assetExecutionIntegrationDocumentationConsistencyPosture`
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
- `assetExecutionSchemaPosture`
- `assetExecutionEnumPosture`
- `assetExecutionReferencePosture`
- `assetExecutionArrayPosture`
- `assetExecutionLimitPosture`
- `assetExecutionSignalPosture`
- `assetExecutionCoordinatorBoundaryPosture`
- `assetExecutionFutureAdapterSeparationPosture`
- `assetExecutionFutureAssetOperationSeparationPosture`
- `assetExecutionFutureGameplaySeparationPosture`
- `assetExecutionIsolationPosture`
- `assetExecutionValidationPosture`
- `assetExecutionLifecyclePosture`
- `assetExecutionNoAuthorityPosture`
- `noExecution`
- `noAssetLoading`
- `noGameplay`
- `noPresentation`
- `noSave`
- `noNetworking`
- `noAnalytics`
- `noTelemetry`

Diagnostics expose copied data only and never expose live handles or authority.

Snapshots expose the same lowerCamelCase posture keys and remain isolated deep copies. Diagnostics and snapshots report health, counts, copied schemas, copied limits, provider identity, snapshot identity, documentation identity, Bootstrap identity, Governance provider identity, and self-check metadata only.

Phase 93 diagnostics also expose copied integration-readiness declarations, order tables, declaration fields, and declaration count. Mutating returned diagnostics cannot mutate the source declarations.

Phase 94 diagnostics add hardening posture keys for declaration exactness, ordering, compatibility identity, order tables, metadata, evidence, tags, adapter contamination, asset-operation contamination, runtime-limit isolation, and documentation consistency. These keys are health-only strings and do not expose adapters, asset-operation providers, routes, dispatch targets, queues, schedulers, orchestration handles, callbacks, listeners, services, modules, remotes, clients, gameplay state, Presentation state, Save state, or Chapter content.

Phase 95 diagnostics and snapshots also expose `adapterReadiness` with copied declarations, copied order tables, copied fields, and declaration count. The posture keys are lowerCamelCase and health-only. Mutating returned diagnostics or snapshots cannot mutate the source adapter-readiness declarations.

Phase 96 adds hardening posture keys for adapter declaration exactness, identity, boundary, documentation, serialization, validation, isolation, limits, Governance provider, and Bootstrap dependency. Diagnostics and snapshots remain deep copies with no mutable references.

Phase 97 diagnostics and snapshots expose `adapterContract` with copied declarations, order tables, fields, and declaration count. New lowerCamelCase contract posture keys are health-only strings and expose no adapter runtime, provider, registry, activation, execution route, queue, scheduler, orchestration, gameplay, Presentation, Save, or Chapter state.
## Phase 98 Adapter Contract Hardening

Diagnostics expose Phase 98 adapter-contract hardening as health-only lowerCamelCase posture. The new keys describe hardening, validation, serialization, isolation, boundary, documentation, Governance, Bootstrap, identity, lifecycle, authority, and operation posture.

Adapter-contract declarations, order tables, and fields remain isolated deep copies in diagnostics and snapshots. No diagnostics object exposes runtime handles, adapter handles, asset operation handles, routes, dispatch targets, queues, scheduler state, orchestration state, gameplay state, Presentation state, Save state, or Chapter content.
