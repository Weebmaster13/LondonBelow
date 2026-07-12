# Asset Execution Adapter Serialization

Serialization exposes copied metadata only.

The serializer validates values before they enter runtime state, diagnostics, snapshots, validation failure history, or self-check output. It accepts only primitive values and table graphs that are bounded, acyclic, metatable-free, instance-free, and free of executable markers.

Rejected payloads include functions, threads, userdata, metatables, instance-shaped tables, cyclic payloads, oversized strings, oversized node graphs, callbacks, listeners, handlers, adapter implementation markers, adapter registry markers, runtime handles, execution handles, asset operation markers, networking markers, persistence markers, analytics markers, telemetry markers, gameplay markers, Presentation markers, Save markers, and Chapter markers.

`Serialization.deepCopy` is the only path used to expose state outside the runtime.
## Phase 102 Production Hardening

Serialization remains copied metadata only and rejects runtime contamination markers for adapter implementations, runtime handles, registry handles, dispatcher handles, scheduler handles, orchestrator handles, callbacks, listeners, services, managers, loaders, factories, executable references, asset operation references, gameplay references, Presentation references, Save references, and Chapter references.

Rejected payloads never mutate state because every registration path validates serialization safety before storing a copied record.
