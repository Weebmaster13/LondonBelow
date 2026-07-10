# Asset Governance Certification Decision Diagnostics

Diagnostics are health-only copied metadata. They expose counts, bounded limit usage, runtime limits, provider names, documentation references, Bootstrap dependency metadata, Governance posture, decision posture, recent sanitized validation failures, and the last sanitized self-check result.

Exact lowerCamelCase posture keys:

- `decisionRuntimePosture`
- `decisionEvaluationPosture`
- `decisionRequirementPosture`
- `decisionAuditPosture`
- `decisionEvidencePosture`
- `decisionIsolationPosture`
- `decisionValidationPosture`
- `decisionMetadataPosture`
- `decisionDocumentationPosture`
- `decisionIntegrationPosture`
- `decisionIntegrationHardeningPosture`
- `integrationOrderingPosture`
- `integrationDeterminismPosture`
- `integrationConsistencyPosture`
- `integrationCompatibilityPosture`
- `integrationEvidencePosture`
- `integrationIsolationPosture`
- `integrationCoveragePosture`
- `integrationValidationPosture`
- `integrationDocumentationPosture`
- `executionReadinessPosture`
- `executionCompatibilityPosture`
- `executionEvidencePosture`
- `executionIsolationPosture`
- `executionCoveragePosture`
- `executionValidationPosture`
- `executionDocumentationPosture`
- `noExecutionAuthorityPosture`
- `noExecutionRoutingPosture`
- `noExecutionDispatchPosture`
- `noExecutionQueuePosture`
- `noExecutionMutationPosture`
- `providerPosture`
- `snapshotPosture`
- `documentationPosture`
- `bootstrapPosture`
- `governancePosture`
- `noAuthorityPosture`
- `noAuthorizationPosture`
- `noApprovalPosture`
- `noRejectionPosture`
- `noExecutionPosture`
- `noRepairPosture`
- `noOrchestrationPosture`
- `noSchedulingPosture`
- `noMutationPosture`

Diagnostics expose copied integration-readiness declarations, integration hardening posture, and copied execution-readiness declarations only. They must never expose services, Instances, threads, userdata, callbacks, listeners, runtime handles, asset handles, loaded assets, execution adapters, repair handlers, authorization handlers, approval handlers, rejection handlers, routing handlers, routing tables, dispatch handlers, dispatch graphs, scheduler queues, execution queues, repair queues, authority tokens, execution tokens, runtime dispatchers, runtime schedulers, future execution handles, live subsystem handles, remotes, mutable runtime references, or client state.

Diagnostics do not authorize, approve, reject, repair, execute, orchestrate, schedule, persist, network, create remotes, grant client authority, execute gameplay, execute Presentation, execute Save, or add Chapter content.
