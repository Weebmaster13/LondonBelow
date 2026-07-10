# Asset Governance Certification Self-Checks

Executable self-checks verify that the certification runtime remains read-only and metadata-only.

Coverage includes provider consistency, snapshot consistency, diagnostic consistency, schema surfaces, enum validation, required fields, duplicate ids, invalid ids, missing certification references, provider matching, dependency ordering, Bootstrap ordering, Governance ordering, runtime count, chain completeness, certification readiness, documentation consistency, serialization, validation-before-mutation, shutdown cleanup, namespace reset, snapshot isolation, diagnostics isolation, bounded histories, runtime limits, and forbidden runtime surface absence.

Phase 62 expands the deterministic executable suite to 784 checks. Phase 63 expands it to 974 checks. Phase 64 expands it to 1,155 checks with copied readiness declaration isolation and exact readiness metadata checks. The expanded coverage verifies:

- exact provider, snapshot, posture, signal-name, mode, schema, enum, and limit surfaces
- diagnostics copied-metadata isolation for dependency order, Bootstrap order, documentation files, and runtime limits
- no-execution and no-mutation posture keys in diagnostics and snapshots
- invalid id, unsupported schema type, duplicate array, non-table array, and missing reference rejection
- forbidden markers as both keys and values
- validation-before-mutation and namespace reuse after rejected schemas
- bounded validation failure and snapshot histories
- integration-readiness posture consistency in diagnostics and snapshots
- dependency, provider, coordinator, Bootstrap, snapshot-provider, diagnostics-provider, and documentation compatibility declarations
- invalid integration-readiness metadata rejection
- exact readiness posture key coverage including `integrationReadinessDeclarations`
- exact certified integration chain coverage through Asset Governance Certification
- diagnostics and snapshots copy each readiness declaration rather than returning runtime tables
- diagnostics-provider values must exactly match `<coordinatorName>.inspect`
- unsafe integration-readiness tags and metadata reject forbidden execution, repair, authorization, orchestration, scheduling, remote, persistence, and live-runtime markers
- duplicate readiness declaration rejection

The self-checks do not require remotes, services, DataStore, HTTP, MessagingService, Workspace, storage mutation, asset loading, orchestration, scheduling, gameplay, Presentation, Save, or Chapter content.
