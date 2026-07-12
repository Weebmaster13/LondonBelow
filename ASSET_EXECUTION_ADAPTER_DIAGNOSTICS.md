# Asset Execution Adapter Diagnostics

Diagnostics are health-only and exposed through `assetExecutionAdapterRuntime`.

Diagnostics expose lifecycle state, health, validation status, counts, limit usage, runtime limits, runtime identity, coordinator identity, provider posture, snapshot posture, documentation posture, Bootstrap posture, Governance snapshot providers, lowerCamelCase posture keys, copied schemas, bounded validation failures, and the last self-check result.

LowerCamelCase posture keys include:

- `assetExecutionAdapterRuntimePosture`
- `assetExecutionAdapterValidationPosture`
- `assetExecutionAdapterCompatibilityPosture`
- `assetExecutionAdapterLifecyclePosture`
- `assetExecutionAdapterCapabilityPosture`
- `assetExecutionAdapterBoundaryPosture`
- `assetExecutionAdapterAuditPosture`
- `assetExecutionAdapterCertificationPosture`

Diagnostics do not expose adapter implementations, adapter registries, runtime handles, callbacks, listeners, execution APIs, routing systems, dispatch systems, schedulers, orchestrators, gameplay state, Presentation state, Save state, Chapter state, or mutable references.
## Phase 102 Production Hardening

Diagnostics remain health-only and expose copied metadata for runtime identity, provider identity, snapshot identity, coordinator identity, documentation posture, Bootstrap posture, Governance snapshot provider posture, runtime limits, and lowerCamelCase hardening posture keys.

The diagnostics posture includes runtime, validation, lifecycle, compatibility, capability, boundary, audit, certification, hardening, identity, ordering, metadata, evidence, tag, limit, diagnostics, and snapshot posture without exposing handles, callbacks, registries, dispatchers, schedulers, orchestrators, or executable references.
