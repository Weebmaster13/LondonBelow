# Asset Execution Serialization

Serialization is deep-copy only. Runtime records, diagnostics, snapshots, runtime limits, documentation arrays, validation failures, evidence, tags, and metadata are copied before exposure.

Serializable payloads may contain primitive values and bounded tables. Serialization rejects functions, threads, userdata, cyclic tables, instance-shaped tables, oversized strings, oversized node counts, excessive depth, unsafe keys, and forbidden runtime-surface markers.

Serialization does not create Instances, touch services, fetch assets, create remotes, persist data, dispatch work, schedule work, or mutate external state.

Phase 92 expands deterministic self-check coverage for forbidden markers across metadata, evidence, tags, schema string fields, nested values, and nested keys. Rejected payloads are copied into diagnostics only through sanitized diagnostic copies, and failed validation does not mutate registered runtime state.

Phase 93 extends forbidden marker coverage for future adapter and handler vocabulary. Integration-readiness declarations remain plain copied tables and reject unsafe metadata, evidence, and tags.
