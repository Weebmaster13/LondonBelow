# Asset Execution Runtime

Phase 91 creates the first dedicated `AssetExecutionRuntime`.

Provider: `assetExecutionRuntime`

Snapshot provider: `assetExecutionRuntime`

Snapshot kind: `assetExecutionRuntimeSnapshot`

Coordinator: `AssetExecutionCoordinator`

Bootstrap dependency: `AssetExecutionAuthorizationCoordinator`

Schemas:

- `ExecutionRuntime`
- `ExecutionRequest`
- `ExecutionBoundary`
- `ExecutionAudit`

The runtime owns execution metadata only. Execution requests, lifecycle state, boundaries, and audits are deterministic records for a future pipeline. They do not load, stream, spawn, apply, display, play, animate, sound, create models, mutate Workspace, grant client authority, own network ownership, run physics, route, dispatch, queue, schedule, orchestrate, persist, use HTTP, use MessagingService, collect analytics, send telemetry, execute gameplay, execute Presentation, execute Save, execute Chapter content, create maps, create rooms, add dialogue, or create cutscenes.
