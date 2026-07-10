# Governance Certification Runtime

`GovernanceCertification` records describe a certification review target.

Fields:

- `certificationId`
- `certificationKind`
- `certificationStatus`
- `chainId`
- `requirementIds`
- `resultIds`
- `auditIds`
- `reviewer`
- `certificationVersion`
- `tags`
- `metadata`

Certification records are eligibility metadata only and do not authorize execution.

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

`requirementIds`, `resultIds`, and `auditIds` are bounded child reference arrays. When supplied, they must reference already registered child records. The runtime does not auto-create children, repair missing children, or resolve records from upstream runtimes.

`reviewer`, `chainId`, and `certificationVersion` are required. `tags` and `metadata` must remain bounded, serializable metadata.
