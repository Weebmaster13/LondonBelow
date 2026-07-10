# Asset Governance Certification Decision Runtime

Phase 73 adds the Asset Governance Certification Decision Runtime Foundation.

Provider and coordinator names:

- runtime name: Asset Governance Certification Decision Runtime
- coordinator: `AssetGovernanceCertificationDecisionCoordinator`
- diagnostics provider: `assetGovernanceCertificationDecisionRuntime`
- snapshot kind: `assetGovernanceCertificationDecisionRuntimeSnapshot`

Owned schemas and exact fields:

`GovernanceDecision`

- `decisionId`
- `inspectionId`
- `decisionKind`
- `decisionStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `requirementIds`
- `evaluationIds`
- `auditIds`
- `evidence`
- `tags`
- `metadata`

`GovernanceDecisionRequirement`

- `requirementId`
- `decisionId`
- `requirementKind`
- `requirementStatus`
- `runtimeName`
- `providerName`
- `snapshotProviderName`
- `evidence`
- `tags`
- `metadata`

`GovernanceDecisionEvaluation`

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

`GovernanceDecisionAudit`

- `auditId`
- `decisionId`
- `evaluationIds`
- `auditKind`
- `auditStatus`
- `reviewer`
- `evidence`
- `tags`
- `metadata`

The runtime evaluates copied governance metadata and records deterministic decision metadata only. Decision records, requirement records, evaluation records, and audit records are evidence. They are not commands, not authorization, not approval, not rejection, not repair orders, not orchestration plans, and not scheduled work.

Diagnostics expose health-only posture keys:

- `decisionRuntimePosture`
- `decisionEvaluationPosture`
- `decisionRequirementPosture`
- `decisionAuditPosture`
- `decisionEvidencePosture`
- `decisionIsolationPosture`
- `decisionValidationPosture`

The runtime registers after `AssetGovernanceCertificationInspectionCoordinator`. It depends on the certified asset governance chain through inspection, but it does not resolve live upstream records or mutate upstream state.

Hard bans remain intact: no asset loading, preloading, streaming, spawning, application, playback, UI, VFX, remotes, client authority, DataStore, HTTP, MessagingService, analytics, telemetry, Workspace mutation, storage mutation, gameplay execution, Presentation execution, Save execution, Chapter content, maps, rooms, dialogue, cutscenes, authorization, approval authority, rejection authority, repair, orchestration, scheduling, live subsystem state, or mutable runtime references.
