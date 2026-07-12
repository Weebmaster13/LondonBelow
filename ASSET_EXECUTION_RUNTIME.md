# Asset Execution Runtime

Phase 91 creates the first dedicated `AssetExecutionRuntime`. Phase 92 production-hardens that runtime without adding a new runtime, provider, coordinator, snapshot provider, or execution behavior.

Provider: `assetExecutionRuntime`

Snapshot provider: `assetExecutionRuntime`

Snapshot kind: `assetExecutionRuntimeSnapshot`

Coordinator: `AssetExecutionCoordinator`

Bootstrap dependency: `AssetExecutionAuthorizationCoordinator`

Canonical posture key: `assetExecutionRuntimePosture`

Schemas:

- `ExecutionRuntime`
- `ExecutionRequest`
- `ExecutionBoundary`
- `ExecutionAudit`

The runtime owns execution metadata only. Execution requests, lifecycle state, boundaries, and audits are deterministic records for a future pipeline. They do not load, stream, spawn, apply, display, play, animate, sound, create models, mutate Workspace, grant client authority, own network ownership, run physics, route, dispatch, queue, schedule, orchestrate, persist, use HTTP, use MessagingService, collect analytics, send telemetry, execute gameplay, execute Presentation, execute Save, execute Chapter content, create maps, create rooms, add dialogue, or create cutscenes.

Phase 92 hardening treats `AssetExecutionTypes.lua` as the source of truth. The implemented `ExecutionRuntime` fields are exactly `runtimeId`, `authorizationId`, `readinessId`, `runtimeKind`, `runtimeStatus`, `providerName`, `snapshotProviderName`, `requestIds`, `boundaryIds`, `auditIds`, `evidence`, `tags`, and `metadata`.

Validation now rejects schema-field drift, enum drift, runtime-limit drift, posture-key drift, coordinator API drift, signal-name drift, provider drift, snapshot-provider drift, and documentation or Governance provider drift before runtime health can pass.

Phase 93 adds 24 static copied integration-readiness declarations inside the same runtime. These declarations prove compatibility with Authorization, readiness evidence, runtime identity, provider identity, snapshot identity, Bootstrap, Governance, docs, schemas, enums, references, serialization, diagnostics, snapshots, runtime limits, signal/coordinator boundaries, lifecycle cleanup, and future separation boundaries.
