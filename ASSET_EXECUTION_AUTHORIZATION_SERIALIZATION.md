# Asset Execution Authorization Serialization

Serialization is deep-copy only. Runtime records, diagnostics, snapshots, limits, documentation arrays, validation failures, evidence, tags, and metadata are copied before exposure.

Serializable payloads may contain primitive values and bounded tables. Serialization rejects functions, threads, userdata, cyclic tables, instance-shaped tables, oversized strings, oversized node counts, excessive depth, unsafe keys, and forbidden runtime-surface markers.

Serialization does not create Instances, touch services, fetch assets, create remotes, persist data, dispatch work, schedule work, or mutate external state.

Phase 86 expands forbidden marker coverage across authority, approval, rejection, permission, routing, dispatch, scheduler, orchestrator, execution, gameplay, Presentation, Save, Chapter, live-handle, and client-state markers. Forbidden markers reject as direct values, nested values, metadata keys, evidence entries, and tag entries. Diagnostic copies return `"<unsafe-payload>"` for unsafe values instead of exposing live references.
