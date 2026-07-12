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
