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
