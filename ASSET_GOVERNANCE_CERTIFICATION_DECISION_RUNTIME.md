# Asset Governance Certification Decision Runtime

Phase 73 adds the Asset Governance Certification Decision Runtime Foundation. Phase 74 production-hardens that runtime without adding authority.

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
- `decisionMetadataPosture`
- `decisionDocumentationPosture`
- `noAuthorizationPosture`
- `noApprovalPosture`
- `noRejectionPosture`
- `noRepairPosture`
- `noExecutionPosture`
- `noOrchestrationPosture`
- `noSchedulingPosture`

The runtime registers after `AssetGovernanceCertificationInspectionCoordinator`. It depends on the certified asset governance chain through inspection, but it does not resolve live upstream records or mutate upstream state.

Phase 74 hardening rejects unsupported fields, invalid ids, invalid child references, duplicate child references, oversized arrays, unsafe payloads, runtime/provider/snapshot mismatches, decision engines, approval handlers, rejection handlers, authorization handlers, repair handlers, execution adapters, orchestration handlers, scheduling handlers, networking markers, persistence markers, and mutable runtime references before mutation.

Hard bans remain intact: no asset loading, preloading, streaming, spawning, application, playback, UI, VFX, remotes, client authority, DataStore, HTTP, MessagingService, analytics, telemetry, Workspace mutation, storage mutation, gameplay execution, Presentation execution, Save execution, Chapter content, maps, rooms, dialogue, cutscenes, authorization, approval authority, rejection authority, repair, orchestration, scheduling, live subsystem state, or mutable runtime references.
