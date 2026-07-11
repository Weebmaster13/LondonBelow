# Asset Execution Governance Runtime

Phase 79 adds the Asset Execution Governance Runtime under `src/ServerScriptService/AssetExecutionGovernance/Core`.

The runtime owns schema-only governance metadata for future asset execution eligibility review. It records copied governance records, requirements, assessments, findings, and audits. It does not authorize, reject, route, schedule, orchestrate, load, preload, stream, spawn, apply, display, play, mutate, or execute assets.

Runtime identity:

- Runtime name: `Asset Execution Governance Runtime`
- Coordinator: `AssetExecutionGovernanceCoordinator`
- Provider: `assetExecutionGovernanceRuntime`
- Snapshot kind: `assetExecutionGovernanceRuntimeSnapshot`
- Posture key: `assetExecutionGovernancePosture`

`Satisfied` is metadata only and is not permission to execute. `Unsatisfied` and `Blocked` are metadata only and are not operational rejection commands.
