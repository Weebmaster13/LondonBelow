# Governance Decision Evaluation Runtime

`GovernanceDecisionEvaluation` records the copied evaluation metadata for one decision requirement.

Exact fields:

- `evaluationId`
- `decisionId`
- `requirementId`
- `evaluationKind`
- `evaluationStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `evidence`
- `tags`
- `metadata`

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

Evaluation records must reference an existing decision and requirement before storage. Runtime, provider, and snapshot provider values must stay consistent with the same certified runtime entry. Unsupported fields reject; the exact fields above are the complete accepted surface.

Evaluation records are deterministic metadata only. They are not commands and cannot authorize execution, approve execution, reject execution, repair records, orchestrate systems, schedule work, mutate state, create remotes, use services, or add gameplay, Presentation, Save, or Chapter behavior.

Phase 76 production-hardens integration-readiness metadata that may reference evaluation compatibility for future governed systems. It remains exact copied metadata only and cannot route, dispatch, authorize, approve, reject, repair, execute, orchestrate, or schedule work.
