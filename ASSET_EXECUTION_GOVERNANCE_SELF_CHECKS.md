# Asset Execution Governance Self-Checks

Self-checks validate provider consistency, schema terminology, exact field counts, exact field names, missing-field rejection, misspelled-field rejection, authority-bearing field rejection, enum acceptance, enum drift rejection, ordered-array validation, reference validation, cross-parent reference rejection, validation-before-mutation behavior, snapshot isolation, diagnostics posture, lowerCamelCase posture keys, shutdown cleanup, no-authority semantics, and banned runtime surface absence.

Phase 81 self-checks also validate provider-name consistency, exact integration-readiness declaration fields, exact declaration count and ordering, integrationKind validation, integrationStatus validation, authorizationBoundaryKind validation, Decision Runtime identity compatibility, execution-readiness evidence compatibility, Asset Execution Governance identity compatibility, Bootstrap compatibility, Engine Governance snapshot provider consistency, documentation compatibility, unsafe integration metadata rejection, diagnostics integration posture, snapshot integration posture, and copied declaration isolation.

Phase 82 self-checks pass at 3,712 checks. The expanded coverage verifies exact declaration order arrays, per-declaration field drift rejection, metadata key rejection, metadata order and compatibility rejection, nested unsafe metadata rejection, declaration rotation rejection, all hardening posture keys, diagnostics runtime-limit isolation, snapshot runtime-limit isolation, and continued banned runtime surface absence.

Self-checks run through `AssetExecutionGovernanceCoordinator.runSelfChecks()` before the runtime is started.
