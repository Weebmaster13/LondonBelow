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
