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
- `authorizationIntegrationReadinessPosture`
- `authorizationIntegrationCompatibilityPosture`
- `authorizationIntegrationHardeningPosture`
- `authorizationIntegrationOrderPosture`
- `authorizationExecutionSeparationPosture`
- `authorizationGameplaySeparationPosture`
- `assetExecutionReadinessPosture`
- `assetExecutionReadinessCompatibilityPosture`
- `assetExecutionReadinessBoundaryPosture`
- `assetExecutionReadinessSeparationPosture`
- `assetExecutionReadinessOrderPosture`
- `assetExecutionReadinessIsolationPosture`
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

Phase 86 diagnostics additionally expose copied `runtimeName`, `coordinatorName`, `governanceSnapshotProviders`, and `identityOrder`. These arrays are deep copies and are verified by self-checks for runtime-limit and identity isolation. Diagnostics remain health-only and cannot approve, reject, route, dispatch, schedule, orchestrate, execute, mutate, or grant authority.

Phase 87 diagnostics additionally expose copied `authorizationIntegrationReadinessDeclarations` and `authorizationIntegrationDeclarationCount`. These are health-only compatibility declarations and do not grant permission, route execution, dispatch work, schedule work, orchestrate systems, execute assets, or mutate gameplay.

Phase 88 diagnostics additionally expose copied `authorizationIntegrationDeclarationOrder`. Mutating returned order arrays cannot mutate `AssetExecutionAuthorizationTypes.IntegrationReadinessDeclarationOrder`. Diagnostics remain health-only and do not expose executable permission, approval, rejection, routing, dispatch, queues, scheduler, orchestration, asset operations, gameplay, Presentation, Save, or Chapter behavior.

Phase 89 diagnostics additionally expose copied `assetExecutionReadinessDeclarations`, `assetExecutionReadinessDeclarationOrder`, and `assetExecutionReadinessDeclarationCount`. Mutating returned readiness declarations or order arrays cannot mutate `AssetExecutionAuthorizationTypes.AssetExecutionReadinessDeclarations` or `AssetExecutionAuthorizationTypes.ExecutionReadinessDeclarationOrder`. Diagnostics remain health-only and do not expose Asset Execution Runtime, executable permission, requests, commands, routing, dispatch, queues, scheduler, orchestration, asset operations, gameplay, Presentation, Save, or Chapter behavior.
