# Asset Execution Governance Diagnostics

Diagnostics are registered under `assetExecutionGovernanceRuntime` and expose health-only metadata:

- lifecycle state
- counts and limit usage
- runtime limits
- schema copies
- recent validation failures
- last self-check result
- provider and snapshot posture
- `assetExecutionGovernancePosture`
- `integrationReadinessPosture`
- `integrationDeclarationPosture`
- `decisionRuntimeCompatibilityPosture`
- `executionReadinessCompatibilityPosture`
- `executionGovernanceCompatibilityPosture`
- `futureAuthorizationSeparationPosture`
- `futureExecutionSeparationPosture`
- `integrationHardeningPosture`
- `declarationOrderingPosture`
- `declarationImmutabilityPosture`
- `compatibilityIdentityPosture`
- `runtimeLimitIsolationPosture`
- copied integration-readiness declaration count and declaration copies
- no-authorization, no-permission, no-operational-rejection, no-routing, no-dispatch, no-queue, no-scheduling, no-orchestration, no-execution, and no-mutation posture

Diagnostics return isolated deep copies and never expose live runtime handles.
