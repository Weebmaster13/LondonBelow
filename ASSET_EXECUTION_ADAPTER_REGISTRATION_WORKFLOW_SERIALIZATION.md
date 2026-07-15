# Asset Execution Adapter Registration Workflow Serialization

Serialization exposes copied metadata only and performs deep-copy isolation.

Serializable payloads may contain bounded strings, numbers, booleans, arrays, and plain tables. Serialization rejects functions, threads, userdata, metatables, instance-shaped tables, cycles, unsafe keys, oversized strings, oversized payload depth, oversized payload node counts, and forbidden runtime markers.

Serialization never exposes adapter implementations, workflow handles, registry handles, runtime handles, dispatcher handles, scheduler handles, execution references, activation references, mutable references, gameplay references, Presentation references, Save references, or Chapter references.

## Phase 106 Production Hardening

Serialization hardening confirms copied metadata isolation and rejects contamination through metadata values, metadata keys, evidence arrays, and tag arrays. It remains non-executable and never returns mutable runtime state.
## Phase 107 Processing Readiness Serialization

Processing-readiness declarations are static copied metadata. Serialization accepts only bounded, acyclic, plain-table payloads and rejects unsafe runtime values, metatables, instance-shaped tables, unsafe keys, unsafe strings, and forbidden operational markers.

The forbidden marker catalog now covers future processor, processor callback/listener/service/manager, workflow run, stage advancement, transition run, decision run, queue, routing, dispatch, scheduler, orchestrator, message-bus, and event-bus contamination while keeping the runtime metadata-only.

## Phase 108 Processing Readiness Production Hardening

The marker catalog additionally rejects processing providers, coordinators, registries, workers, jobs, runtimes, handles, callbacks, listeners, services, managers, registration processors, and registry-write contamination in metadata keys, values, evidence, and tags.
