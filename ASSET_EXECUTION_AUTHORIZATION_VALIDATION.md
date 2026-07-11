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

Phase 88 validates the exact declaration field set before deeper payload validation, then checks each declaration index against `IntegrationReadinessDeclarationOrder`. The order arrays cover every scalar hardening field from `integrationId` through `required`; evidence, tags, and metadata remain exact through deep copied value validation. Drifted order arrays, missing order arrays, sparse order arrays, extra order entries, replaced declarations, duplicate declaration identities, enum casing drift, whitespace drift, prefixed enum values, suffixed enum values, plural enum values, boolean enum values, numeric enum values, table enum values, permission fields, token fields, execution fields, routing fields, dispatch fields, queue fields, scheduler fields, orchestrator fields, handler fields, adapter fields, asset handles, runtime handles, and client-state fields reject.

Phase 89 validates `AssetExecutionReadinessDeclarations` as exact copied metadata. The field set is fixed from `readinessId` through `metadata`, `readinessKind` and `readinessStatus` must use supported enums, and each scalar field is checked against `ExecutionReadinessDeclarationOrder`. Validation also verifies Governance identity, Governance provider, Governance snapshot provider, Authorization runtime identity, Authorization provider, Authorization snapshot provider, Authorization coordinator, Bootstrap dependency, Engine Governance snapshot provider, documentation references, future execution runtime/provider/snapshot/coordinator separation, copied evidence, copied tags, copied metadata, and required flags. Failed readiness validation never mutates runtime state.

Phase 90 hardens readiness validation by requiring the `ExecutionReadinessDeclarationOrder` table itself to be exact. Missing order arrays, extra order arrays, non-table order arrays, sparse order arrays, dictionary-shaped order arrays, extra order entries, and scalar order drift reject before health validation passes. The readiness declaration set also rejects insertion, deletion, replacement, rotation, reversal, duplicate readiness ids, duplicate compatibility ids, duplicate declaration ids, unsupported metadata, metadata drift, evidence drift, tag drift, nested unsafe metadata, runtime-handle markers, callback markers, remote markers, permission markers, approval markers, routing markers, dispatch markers, queue markers, scheduler markers, orchestration markers, execution markers, asset-operation markers, gameplay markers, Presentation markers, Save markers, and Chapter markers.
