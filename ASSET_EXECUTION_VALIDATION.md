# Asset Execution Validation

Validation rejects nil schemas, non-table schemas, unsupported fields, missing fields, invalid ids, unsupported enum values, duplicate global ids, invalid references, unsafe metadata, unsafe evidence, unsafe tags, cyclic payloads, instance-shaped payloads, oversized payloads, and bounded-limit violations before state mutation.

`ExecutionRuntime`, `ExecutionRequest`, `ExecutionBoundary`, and `ExecutionAudit` each validate exact fields from `AssetExecutionTypes.SchemaFields`.

`ExecutionRequest` and `ExecutionBoundary` require an existing runtime. `ExecutionAudit` requires an existing runtime and existing request and boundary references that belong to the same runtime.

Failed validation records a bounded diagnostic failure and never mutates registered schema state.

Phase 92 hardening also validates the canonical Type tables themselves. Runtime identity, schema fields, schema field counts, enum sets, runtime limits, posture keys, documentation references, Bootstrap dependency order, Governance snapshot providers, coordinator API names, and signal names must match the certified values exactly.

Child reference arrays must be ordered, dense, duplicate-free arrays. Runtime child references and audit child references must point to records owned by the same runtime before mutation is allowed.

Phase 93 validation adds exact integration-readiness declaration checks. The 24 copied declarations must preserve exact field names, count, order tables, ids, enum values, identities, boundary kinds, required flags, evidence, tags, and metadata. Drift rejects before runtime health can pass and does not mutate registered schema state.

Phase 94 hardens the Phase 93 layer by validating the integration-readiness declaration set against an independent 24-row certified contract. The validator rejects declaration deletion, insertion, replacement, reordering, rotation, reversal, sparse arrays, dictionary-shaped arrays, unsupported order tables, missing order tables, order-table drift, enum casing drift, identity aliases, metadata drift, evidence drift, tag drift, adapter contamination, asset-operation contamination, and gameplay contamination.

Validation remains static and non-mutating. Failed integration-readiness validation does not alter registered `ExecutionRuntime`, `ExecutionRequest`, `ExecutionBoundary`, or `ExecutionAudit` records, runtime counts, global ids, lifecycle state, runtime limits, provider identity, snapshot identity, Bootstrap dependency, Governance provider, signal names, coordinator API names, declarations, or order tables.

Phase 95 adds exact adapter-readiness validation for 38 static copied declarations. The validator checks exact field names, declaration count, order tables, provider identities, execution runtime identities, future adapter absence identities, `readinessKind`, `readinessStatus`, `adapterKind`, `adapterAuthorityKind`, `adapterBoundaryKind`, `assetOperationBoundaryKind`, `lifecycleBoundaryKind`, required flags, evidence, tags, metadata, dense arrays, duplicate ids, and unsafe payloads.

Failed adapter-readiness validation is non-mutating and cannot change registered schema records, global ids, counts, lifecycle state, runtime limits, Phase 93 integration declarations, Phase 95 adapter-readiness declarations, or order tables.

Phase 96 expands adapter-readiness hardening. The validator and self-checks reject deletion, insertion, replacement, reversal, rotation, sparse arrays, dictionary-shaped arrays, unsupported fields, unsupported order tables, missing order tables, duplicate ids, identity aliases, enum drift, punctuation drift, casing drift, whitespace drift, nested unsafe payloads, metadata drift, evidence drift, and tag drift without mutating runtime state.

Phase 97 adds exact adapter-contract validation for 24 static copied declarations. The validator checks exact field order, declaration order, order tables, provider identities, future adapter absence markers, contract enums, lifecycle boundaries, serialization boundaries, validation boundaries, authority boundaries, operation boundaries, copied evidence, copied tags, copied metadata, and failed-validation no-mutation behavior.
## Phase 98 Adapter Contract Hardening

Validation now treats adapter-contract readiness as frozen copied evidence. It verifies exact declaration count, order, identity, fields, required flags, provider names, snapshot provider, diagnostics provider, coordinator, runtime, Governance provider, Bootstrap dependency, compatibility ids, contract ids, declaration ids, boundary enums, evidence arrays, tag arrays, and metadata keys.

Invalid adapter-contract payloads fail before mutation. Reordered, inserted, deleted, duplicated, truncated, expanded, sparse, dictionary-shaped, mixed-type, aliased, whitespace-drifted, punctuation-drifted, casing-drifted, prefix-drifted, suffix-drifted, unsafe, or contaminated declarations are rejected.
