# Asset Execution Governance Self-Checks

Self-checks validate provider consistency, schema terminology, exact field counts, exact field names, missing-field rejection, misspelled-field rejection, authority-bearing field rejection, enum acceptance, enum drift rejection, ordered-array validation, reference validation, cross-parent reference rejection, validation-before-mutation behavior, snapshot isolation, diagnostics posture, lowerCamelCase posture keys, shutdown cleanup, no-authority semantics, and banned runtime surface absence.

Self-checks run through `AssetExecutionGovernanceCoordinator.runSelfChecks()` before the runtime is started.
