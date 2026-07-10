# Asset Governance Certification Validation

Validation occurs before mutation. Failed validation records a bounded sanitized failure and never registers schema data.

Validation rejects nil schemas, non-table schemas, invalid ids, duplicate ids, missing certification references, unsupported certification kinds/statuses, unsupported requirement kinds/statuses, unsupported result kinds/statuses, unsupported audit kinds/statuses, unsafe metadata, unsafe findings, unsafe evidence, unsafe tags, functions, threads, userdata, Instance-shaped tables, runtime handles, asset handles, loaded assets, module references, execution adapters, callbacks, listeners, services, cycles, oversized payloads, deep payloads, oversized strings, and forbidden execution markers.

Certification metadata does not authorize execution and does not mutate upstream runtimes.

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
