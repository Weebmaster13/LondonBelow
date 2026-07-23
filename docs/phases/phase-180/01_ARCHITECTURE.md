# Phase 180 Architecture

Phase 180 adds `RuntimePresentationRenderingExecution` and `PresentationRenderingExecutionCoordinator` under `src/ServerScriptService/Presentation/Core`.

Runtime identity:

- Provider: `presentationRenderingExecution`
- Runtime id: `presentationRenderingExecutionRuntime`
- Authority: Server
- Bootstrap order: immediately after `PresentationRenderingRuntimeCoordinator`

The runtime owns metadata-only renderer execution state. It consumes prior rendering runtime session ids and renderer ids as stable references, then manages execution sessions through registries, queues, schedulers, lifecycle transitions, acknowledgements, synchronization, diagnostics, snapshots, evidence, and Governance.

It intentionally stops before any Roblox-specific renderer implementation. Phase 181 owns that next boundary.
