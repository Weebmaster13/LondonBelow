# Asset Governance Certification Inspection Validation

Validation rejects nil schemas, non-table schemas, invalid ids, duplicate ids, unsupported schema types, unsupported enum values, invalid runtime names, invalid provider names, invalid snapshot providers, missing inspection references, missing observation references, missing finding references, unsafe metadata, unsafe evidence, unsafe findings, cycles, oversized strings, deep payloads, oversized node counts, functions, threads, userdata, Instance-shaped tables, runtime handles, callbacks, listeners, module references, execution adapters, repair markers, authorization markers, mutation markers, orchestration markers, scheduling markers, networking markers, persistence markers, and live subsystem markers.

Accepted enum values:

`inspectionKind`: `BootstrapHealthInspection`, `CertificationHealthInspection`, `DiagnosticsHealthInspection`, `DocumentationHealthInspection`, `FutureHealthInspection`, `GovernanceHealthInspection`, `ProviderHealthInspection`, `RuntimeCompatibilityInspection`, `SnapshotHealthInspection`

`inspectionStatus`: `Blocked`, `Deferred`, `Draft`, `Inspecting`, `Passed`, `Ready`, `Warning`

`observationKind`: `BootstrapPostureObservation`, `CopiedDiagnosticsObservation`, `CopiedSnapshotObservation`, `DocumentationPostureObservation`, `FutureObservation`, `GovernancePostureObservation`, `ProviderPostureObservation`, `RuntimeCompatibilityObservation`, `SnapshotPostureObservation`

`observationStatus`: `Consistent`, `Deferred`, `Inconsistent`, `Missing`, `Observed`, `Warning`

`health`: `Deferred`, `Healthy`, `Missing`, `Unknown`, `Unhealthy`, `Warning`

`findingKind`: `BootstrapMismatch`, `DiagnosticsMismatch`, `DocumentationMismatch`, `FutureFinding`, `GovernanceMismatch`, `ProviderMismatch`, `RuntimeCompatibilityMismatch`, `SnapshotMismatch`, `UnsafeEvidence`

`findingSeverity`: `Critical`, `Deferred`, `Error`, `Info`, `Warning`

`findingStatus`: `Confirmed`, `Deferred`, `Dismissed`, `NeedsReview`, `Reported`

`auditKind`: `CoverageAudit`, `FindingAudit`, `FutureAudit`, `InspectionAudit`, `ObservationAudit`, `ProductionAudit`, `ProviderAudit`, `SnapshotAudit`

`auditStatus`: `Blocked`, `Deferred`, `Failed`, `Passed`, `Warning`

Validation always occurs before mutation. Failed validation records a sanitized validation failure and never stores the rejected schema.

Phase 70 also validates the exact static integration-readiness declaration set. Validation rejects invalid declaration counts, duplicate readiness ids, duplicate runtime names, duplicate provider names, duplicate snapshot provider names, duplicate coordinator names, duplicate diagnostics provider names, invalid readiness ids, unsupported readiness kinds, unsupported readiness statuses, invalid runtime compatibility ids, provider mismatch, snapshot provider mismatch, coordinator mismatch, diagnostics provider mismatch, documentation mismatch, unsafe readiness metadata, execution markers, repair markers, mutation markers, authorization markers, scheduling markers, orchestration markers, network markers, persistence markers, callbacks, handles, and live runtime references.

Accepted readiness values:

`readinessKind`: `BootstrapCompatibility`, `DocumentationCompatibility`, `GovernanceCompatibility`, `InspectionCoverageCompatibility`, `IntegrationCompatibility`, `ProviderCompatibility`, `RuntimeCompatibility`, `SnapshotCompatibility`

`readinessStatus`: `Compatible`, `Declared`, `Deferred`, `Ready`, `Warning`

Phase 71 also validates the exact static decision-readiness declaration set. Validation rejects invalid declaration counts, duplicate decision readiness ids, duplicate decision compatibility ids, duplicate decision declaration ids, duplicate runtime names, duplicate provider names, duplicate snapshot provider names, duplicate coordinator names, duplicate diagnostics provider names, invalid decision readiness ids, unsupported decision readiness kinds, unsupported decision readiness statuses, provider mismatch, runtime mismatch, snapshot mismatch, Bootstrap mismatch, Governance mismatch, documentation mismatch, unsafe decision metadata, unsafe copied evidence, unsafe findings, unsafe audits, decision markers, approval markers, authorization markers, execution markers, repair markers, mutation markers, orchestration markers, scheduling markers, network markers, persistence markers, callbacks, listeners, handles, and live subsystem references.

Accepted decision-readiness values:

`decisionReadinessKind`: `BootstrapDecisionCompatibility`, `CopiedEvidenceDecisionReadiness`, `DocumentationDecisionCompatibility`, `GovernanceDecisionCompatibility`, `InspectionDecisionCoverage`, `ProviderDecisionCompatibility`, `RuntimeDecisionCompatibility`, `SnapshotDecisionCompatibility`

`decisionReadinessStatus`: `Compatible`, `DecisionReady`, `Declared`, `Deferred`, `ObservationOnly`, `Warning`

Decision-readiness validation proves future decision systems can receive deterministic copied evidence. It does not decide, repair, authorize execution, mutate runtime state, inspect mutable runtime state, orchestrate systems, schedule work, persist data, network, or execute.
