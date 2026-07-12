# ExecutionRuntime Schema

`ExecutionRuntime` is the root metadata record for the Asset Execution Runtime.

It records runtime identity, Authorization and readiness references, runtime kind, runtime status, provider identity, snapshot provider identity, child request ids, boundary ids, audit ids, evidence, tags, and metadata.

Exact fields:

- `runtimeId`
- `authorizationId`
- `readinessId`
- `runtimeKind`
- `runtimeStatus`
- `providerName`
- `snapshotProviderName`
- `requestIds`
- `boundaryIds`
- `auditIds`
- `evidence`
- `tags`
- `metadata`

It does not execute assets or gameplay.

Phase 93 integration-readiness declarations reference `ExecutionRuntime` schema stability as copied metadata only. They do not add executable fields to this schema.

Phase 94 hardens that copied schema-stability evidence without changing `ExecutionRuntime` fields or adding execution behavior.
