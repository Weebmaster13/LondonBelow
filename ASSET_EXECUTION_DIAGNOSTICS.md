# Asset Execution Diagnostics

Diagnostics are health-only and exposed through `assetExecutionRuntime`.

Diagnostics include lifecycle state, validation health, schema counts, limit usage, copied runtime limits, provider posture, snapshot posture, documentation posture, Bootstrap dependency posture, Governance snapshot provider posture, copied schemas, recent validation failures, and latest self-check result.

LowerCamelCase posture keys include:

- `assetExecutionRuntimePosture`
- `assetExecutionRequestPosture`
- `assetExecutionBoundaryPosture`
- `assetExecutionAuditPosture`
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
