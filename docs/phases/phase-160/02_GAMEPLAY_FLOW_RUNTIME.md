# Gameplay Flow Runtime

`ServerScriptService/Gameplay/Flow` contains the Phase 160 runtime.

Primary modules:

- `GameplayFlowCoordinator`
- `GameplayFlowRuntime`
- `GameplayFlowObjectiveRegistry`
- `GameplayFlowObjectiveState`
- `GameplayFlowObjectiveEvaluation`
- `GameplayFlowObjectiveConditions`
- `GameplayFlowDiagnostics`
- `GameplayFlowObjectiveSnapshots`
- `GameplayFlowEvidence`
- `GameplayFlowSelfChecks`

The coordinator registers the lowerCamelCase provider `gameplayFlowRuntime` with Diagnostics and SnapshotManager. Runtime mutation is only available through server-side module APIs.
