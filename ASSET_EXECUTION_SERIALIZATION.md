# Asset Execution Serialization

Serialization is deep-copy only. Runtime records, diagnostics, snapshots, runtime limits, documentation arrays, validation failures, evidence, tags, and metadata are copied before exposure.

Serializable payloads may contain primitive values and bounded tables. Serialization rejects functions, threads, userdata, cyclic tables, instance-shaped tables, oversized strings, oversized node counts, excessive depth, unsafe keys, and forbidden runtime-surface markers.

Serialization does not create Instances, touch services, fetch assets, create remotes, persist data, dispatch work, schedule work, or mutate external state.

Phase 92 expands deterministic self-check coverage for forbidden markers across metadata, evidence, tags, schema string fields, nested values, and nested keys. Rejected payloads are copied into diagnostics only through sanitized diagnostic copies, and failed validation does not mutate registered runtime state.

Phase 93 extends forbidden marker coverage for future adapter and handler vocabulary. Integration-readiness declarations remain plain copied tables and reject unsafe metadata, evidence, and tags.

Phase 94 confirms integration-readiness copies cannot leak shared mutable references through diagnostics, snapshots, or self-check results. The same serializer protects exact declarations, order tables, evidence, tags, metadata, runtime limits, documentation arrays, signal metadata, and coordinator API metadata.

Phase 95 applies the same deep-copy serialization boundary to adapter-readiness declarations. Adapter-readiness declarations, order tables, fields, evidence, tags, metadata, diagnostics, and snapshots remain copied tables only and reject forbidden runtime-surface markers before runtime health can pass.

Phase 96 expands serializer protection for adapter callback, adapter listener, adapter service, adapter registry, adapter module, adapter activation, execution route, execution dispatch, execution queue, execution scheduling, execution orchestration, gameplay, Presentation, Save, Chapter, remote, client-authority, Workspace, and storage-mutation markers. These markers are rejected as payload data and do not create runtime behavior.

Phase 97 expands serializer protection for adapter implementation, adapter manager, adapter loader, execution API, execution handler, route, queue, scheduler, orchestrator, gameplay, Presentation, Save, and Chapter markers. Adapter-contract declarations remain copied tables only.
