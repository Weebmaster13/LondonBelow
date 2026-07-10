# Asset Governance Certification Decision Validation

Phase 74 validation is strict and exact. Accepted schema fields are exactly the fields listed in `AssetGovernanceCertificationDecisionTypes.SchemaFields`; unsupported fields reject before mutation.

Validation rejects nil schemas, non-table schemas, invalid ids, unsupported fields, unsupported enum values, invalid runtime names, invalid provider names, invalid snapshot provider names, provider/runtime/snapshot mismatches, duplicate global ids, missing decision references, missing requirement references, missing evaluation references, duplicate child references, oversized child arrays, oversized evidence arrays, oversized tag arrays, unsafe metadata, unsafe evidence, unsafe tags, unsafe audit evidence, cycles, oversized strings, deep payloads, oversized node counts, functions, threads, userdata, Instance-shaped tables, runtime handles, asset handles, loaded asset handles, callbacks, listeners, services, module references, execution adapters, decision engines, decision trees, decision graphs, approval logic, approval handlers, rejection handlers, authorization handlers, repair handlers, orchestration handlers, scheduling handlers, networking markers, persistence markers, DataStore markers, HTTP markers, Messaging markers, analytics markers, telemetry markers, client authority markers, Workspace mutation markers, and Chapter content markers.

Accepted `decisionKind` values:

- `BootstrapDecisionEvaluation`
- `CertificationDecisionEvaluation`
- `DocumentationDecisionEvaluation`
- `FutureDecisionEvaluation`
- `GovernanceDecisionEvaluation`
- `ProviderDecisionEvaluation`
- `RuntimeDecisionEvaluation`
- `SnapshotDecisionEvaluation`

Accepted `decisionStatus` values:

- `Blocked`
- `Deferred`
- `Evaluated`
- `Satisfied`
- `Unsatisfied`
- `Warning`

Accepted `requirementKind` values:

- `BootstrapConsistencyRequirement`
- `CopiedEvidenceRequirement`
- `DocumentationConsistencyRequirement`
- `FutureRequirement`
- `GovernanceConsistencyRequirement`
- `ProviderConsistencyRequirement`
- `RuntimeConsistencyRequirement`
- `SnapshotConsistencyRequirement`

Accepted `requirementStatus` values:

- `Deferred`
- `Required`
- `Satisfied`
- `Unsatisfied`
- `Warning`

Accepted `evaluationKind` values:

- `BootstrapConsistencyEvaluation`
- `CopiedEvidenceEvaluation`
- `DocumentationConsistencyEvaluation`
- `FutureEvaluation`
- `GovernanceConsistencyEvaluation`
- `ProviderConsistencyEvaluation`
- `RuntimeConsistencyEvaluation`
- `SnapshotConsistencyEvaluation`

Accepted `evaluationStatus` values:

- `Blocked`
- `Deferred`
- `Failed`
- `Passed`
- `Warning`

Accepted `auditKind` values:

- `CoverageAudit`
- `DecisionAudit`
- `EvaluationAudit`
- `FutureAudit`
- `ProductionAudit`
- `ProviderAudit`
- `RequirementAudit`

Accepted `auditStatus` values:

- `Blocked`
- `Deferred`
- `Failed`
- `Passed`
- `Warning`

Validation always occurs before mutation. Rejected data never registers ids, increments counts, creates child records, or stores unsafe payloads. Failed coordinator registration records only bounded sanitized validation failure metadata.
