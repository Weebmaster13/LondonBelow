# Asset Execution Adapter Registry Serialization

Serialization exposes copied metadata only.

The registry serialization layer validates every nested value before storage or diagnostic copying. It rejects functions, threads, userdata, metatables, cycles, instance-shaped payloads, oversized strings, excessive depth, excessive node count, executable contamination, registry handle contamination, runtime handle contamination, adapter implementation contamination, asset-operation contamination, gameplay contamination, Presentation contamination, Save contamination, Chapter contamination, and mutable runtime references.

Serialization does not load assets, stream assets, spawn assets, apply assets, play assets, create remotes, call services, execute adapters, or mutate Workspace/storage.

## Phase 104 Production Hardening

Serialization rejects adapter implementation refs, activation handles, registry handles, runtime handles, dispatcher handles, scheduler handles, router handles, orchestrator handles, callbacks, listeners, services, managers, loaders, factories, execution references, asset-operation references, gameplay references, Presentation references, Save references, Chapter references, network handles, analytics markers, and telemetry markers.

All accepted payloads remain copied metadata only.
