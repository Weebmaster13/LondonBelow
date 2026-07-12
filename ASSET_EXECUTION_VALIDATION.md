# Asset Execution Validation

Validation rejects nil schemas, non-table schemas, unsupported fields, missing fields, invalid ids, unsupported enum values, duplicate global ids, invalid references, unsafe metadata, unsafe evidence, unsafe tags, cyclic payloads, instance-shaped payloads, oversized payloads, and bounded-limit violations before state mutation.

`ExecutionRuntime`, `ExecutionRequest`, `ExecutionBoundary`, and `ExecutionAudit` each validate exact fields from `AssetExecutionTypes.SchemaFields`.

`ExecutionRequest` and `ExecutionBoundary` require an existing runtime. `ExecutionAudit` requires an existing runtime and existing request and boundary references that belong to the same runtime.

Failed validation records a bounded diagnostic failure and never mutates registered schema state.

Phase 92 hardening also validates the canonical Type tables themselves. Runtime identity, schema fields, schema field counts, enum sets, runtime limits, posture keys, documentation references, Bootstrap dependency order, Governance snapshot providers, coordinator API names, and signal names must match the certified values exactly.

Child reference arrays must be ordered, dense, duplicate-free arrays. Runtime child references and audit child references must point to records owned by the same runtime before mutation is allowed.

Phase 93 validation adds exact integration-readiness declaration checks. The 24 copied declarations must preserve exact field names, count, order tables, ids, enum values, identities, boundary kinds, required flags, evidence, tags, and metadata. Drift rejects before runtime health can pass and does not mutate registered schema state.
