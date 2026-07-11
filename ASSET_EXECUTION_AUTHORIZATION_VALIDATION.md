# Asset Execution Authorization Validation

Validation rejects nil schemas, non-table schemas, unsupported fields, missing fields, invalid ids, unsupported enum values, duplicate global ids, missing parent references, unsafe payloads, and bounded-limit violations before state mutation.

`ExecutionAuthorization` fields:

- `authorizationId`
- `governanceId`
- `readinessId`
- `authorizationKind`
- `authorizationStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `requirementIds`
- `evaluationIds`
- `boundaryIds`
- `auditIds`
- `evidence`
- `tags`
- `metadata`

Child schemas validate `requirementKind`, `requirementStatus`, `evaluationKind`, `evaluationStatus`, `boundaryKind`, `boundaryStatus`, `auditKind`, and `auditStatus`. Ordered arrays must be non-sparse and duplicate-free. Failed validation records a bounded diagnostic failure and never mutates registered schema state.

Phase 86 requires ordered arrays to be deterministic ascending arrays, which rejects duplicated, rotated, reordered, sparse, dictionary-shaped, and partial child-reference replacements. Runtime/provider/snapshot/coordinator identity, Bootstrap ordering, Governance snapshot provider ordering, and documentation reference ordering are validated against `AssetExecutionAuthorizationTypes`.

Metadata keys must be valid deterministic ids. Unsafe evidence, tags, metadata, nested metadata markers, unsafe keys, unsafe values, authority markers, approval markers, permission markers, routing markers, dispatch markers, scheduler markers, orchestrator markers, execution markers, gameplay markers, Presentation markers, Save markers, and Chapter markers reject before mutation.

Phase 87 validates `AuthorizationIntegrationReadinessDeclarations` as exact copied metadata. Validation rejects nil, non-table, sparse, dictionary-shaped, reordered, replaced, rotated, reversed, missing-field, unsupported-field, unsupported-kind, unsupported-status, unsupported-boundary, identity-drifted, provider-drifted, snapshot-drifted, coordinator-drifted, Bootstrap-drifted, Governance-drifted, documentation-drifted, unsafe, authority-bearing, permission-bearing, routing-bearing, dispatch-bearing, scheduler-bearing, orchestration-bearing, execution-bearing, gameplay-bearing, Presentation-bearing, Save-bearing, and Chapter-bearing declarations before runtime initialization.
