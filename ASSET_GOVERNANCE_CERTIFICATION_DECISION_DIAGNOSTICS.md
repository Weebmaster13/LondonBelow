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

Diagnostics must never expose services, Instances, threads, userdata, callbacks, listeners, runtime handles, asset handles, loaded assets, execution adapters, repair handlers, authorization handlers, approval handlers, rejection handlers, remotes, mutable runtime references, or client state.

Diagnostics do not authorize, approve, reject, repair, execute, orchestrate, schedule, persist, network, create remotes, grant client authority, execute gameplay, execute Presentation, execute Save, or add Chapter content.
