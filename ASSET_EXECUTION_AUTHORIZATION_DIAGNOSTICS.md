# Asset Execution Authorization Diagnostics

Diagnostics are health-only and exposed through `assetExecutionAuthorizationRuntime`.

Diagnostics include lifecycle state, validation health, schema counts, limit usage, copied runtime limits, provider posture, snapshot posture, documentation posture, Bootstrap dependency posture, copied schemas, recent validation failures, and the latest self-check result.

LowerCamelCase posture keys include:

- `assetExecutionAuthorizationPosture`
- `authorizationRuntimePosture`
- `authorizationIsolationPosture`
- `authorizationBoundaryPosture`
- `authorizationEvaluationPosture`
- `authorizationAuditPosture`
- `authorizationRequirementPosture`
- `noExecution`
- `noRouting`
- `noDispatch`
- `noScheduler`
- `noOrchestration`
- `noGameplay`
- `noPresentation`
- `noSave`
- `noAuthorityEscalation`

Diagnostics never expose live handles and never grant authority.
