# Asset Execution Validation

Validation rejects nil schemas, non-table schemas, unsupported fields, missing fields, invalid ids, unsupported enum values, duplicate global ids, invalid references, unsafe metadata, unsafe evidence, unsafe tags, cyclic payloads, instance-shaped payloads, oversized payloads, and bounded-limit violations before state mutation.

`ExecutionRuntime`, `ExecutionRequest`, `ExecutionBoundary`, and `ExecutionAudit` each validate exact fields from `AssetExecutionTypes.SchemaFields`.

`ExecutionRequest` and `ExecutionBoundary` require an existing runtime. `ExecutionAudit` requires an existing runtime and existing request and boundary references that belong to the same runtime.

Failed validation records a bounded diagnostic failure and never mutates registered schema state.
