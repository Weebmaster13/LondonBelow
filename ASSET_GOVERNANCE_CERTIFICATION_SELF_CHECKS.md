# Asset Governance Certification Self-Checks

Executable self-checks verify that the certification runtime remains read-only and metadata-only.

Coverage includes provider consistency, snapshot consistency, diagnostic consistency, schema surfaces, enum validation, required fields, duplicate ids, invalid ids, missing certification references, provider matching, dependency ordering, Bootstrap ordering, Governance ordering, runtime count, chain completeness, certification readiness, documentation consistency, serialization, validation-before-mutation, shutdown cleanup, namespace reset, snapshot isolation, diagnostics isolation, bounded histories, runtime limits, and forbidden runtime surface absence.

Phase 62 expands the deterministic executable suite to 784 checks. The expanded coverage verifies:

- exact provider, snapshot, posture, signal-name, mode, schema, enum, and limit surfaces
- diagnostics copied-metadata isolation for dependency order, Bootstrap order, documentation files, and runtime limits
- no-execution and no-mutation posture keys in diagnostics and snapshots
- invalid id, unsupported schema type, duplicate array, non-table array, and missing reference rejection
- forbidden markers as both keys and values
- validation-before-mutation and namespace reuse after rejected schemas
- bounded validation failure and snapshot histories

The self-checks do not require remotes, services, DataStore, HTTP, MessagingService, Workspace, storage mutation, asset loading, orchestration, scheduling, gameplay, Presentation, Save, or Chapter content.
