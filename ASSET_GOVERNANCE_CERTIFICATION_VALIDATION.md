# Asset Governance Certification Validation

Validation occurs before mutation. Failed validation records a bounded sanitized failure and never registers schema data.

Validation rejects nil schemas, non-table schemas, invalid ids, duplicate ids, missing certification references, unsupported certification kinds/statuses, unsupported requirement kinds/statuses, unsupported result kinds/statuses, unsupported audit kinds/statuses, unsafe metadata, unsafe findings, unsafe evidence, unsafe tags, functions, threads, userdata, Instance-shaped tables, runtime handles, asset handles, loaded assets, module references, execution adapters, callbacks, listeners, services, cycles, oversized payloads, deep payloads, oversized strings, and forbidden execution markers.

Certification metadata does not authorize execution and does not mutate upstream runtimes.

Phase 63 adds validation for integration-readiness metadata declarations. Phase 64 hardens that validation by treating the declarations as exact static compatibility evidence only. They do not resolve upstream runtime state, mutate runtime records, repair records, or authorize execution.

Accepted `certificationKind` values:

- `GovernanceChainCertification`
- `ProviderCertification`
- `DependencyCertification`
- `BootstrapCertification`
- `DocumentationCertification`
- `FutureCertification`

Accepted `certificationStatus` values:

- `Draft`
- `Eligible`
- `Certified`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `requirementKind` values:

- `RuntimePresenceRequirement`
- `ProviderConsistencyRequirement`
- `DependencyOrderingRequirement`
- `GovernanceContractRequirement`
- `DiagnosticsCompatibilityRequirement`
- `SnapshotCompatibilityRequirement`
- `BootstrapOrderingRequirement`
- `DocumentationCompletenessRequirement`
- `IntegrationReadinessRequirement`
- `FutureRequirement`

Accepted `status` values for `GovernanceCertificationRequirement`:

- `Passed`
- `Failed`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `resultKind` values:

- `EligibilityResult`
- `ProviderResult`
- `DependencyResult`
- `GovernanceResult`
- `DiagnosticsResult`
- `SnapshotResult`
- `BootstrapResult`
- `DocumentationResult`
- `IntegrationResult`
- `FutureResult`

Accepted `resultStatus` values:

- `Passed`
- `Failed`
- `Warning`
- `Blocked`
- `NeedsReview`
- `Deferred`

Accepted `auditKind` values:

- `CertificationAudit`
- `ProviderAudit`
- `DependencyAudit`
- `GovernanceAudit`
- `ProductionAudit`
- `FutureAudit`

Accepted `status` values for `GovernanceCertificationAudit`:

- `Passed`
- `Failed`
- `Warning`
- `Deferred`
- `Blocked`

`GovernanceCertification` child reference lists are validated against already registered child records when provided. Child records require an already registered `certificationId`. This preserves the current implementation contract exactly and does not add cross-runtime repair or automatic relationship creation.

Accepted `integrationReadinessKind` values:

- `DependencyChainReadiness`
- `BootstrapReadiness`
- `GovernanceReadiness`
- `ProviderReadiness`
- `SnapshotProviderReadiness`
- `DiagnosticsReadiness`
- `DocumentationReadiness`
- `RuntimeCompatibilityReadiness`
- `CertificationScopeReadiness`
- `FutureIntegrationReadiness`

Accepted `integrationReadinessState` values:

- `Ready`
- `NeedsReview`
- `Blocked`
- `Deferred`

Integration-readiness declarations validate:

- `readinessId`
- `readinessKind`
- `readinessState`
- `runtimeName`
- `providerName`
- `coordinatorName`
- `bootstrapAfter`
- `snapshotProvider`
- `diagnosticsProvider`
- `documentationFile`
- `required`
- `summary`
- `tags`
- `metadata`

Validation rejects invalid dependency declarations, invalid provider references, invalid coordinator references, invalid Bootstrap references, invalid snapshot provider references, invalid diagnostics provider references, invalid documentation references, duplicate readiness ids, duplicate runtime names, duplicate provider names, unsupported readiness kinds, unsupported readiness states, unsafe tags, unsafe readiness metadata, non-boolean `required`, empty `summary`, and declaration count drift.

`diagnosticsProvider` must exactly match `<coordinatorName>.inspect`. `snapshotProvider` must match the declared provider for upstream runtimes and `assetGovernanceCertificationRuntime` for Asset Governance Certification.
