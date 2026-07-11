# Asset Execution Governance Self-Checks

Self-checks validate provider consistency, schema terminology, enum acceptance and rejection, reference validation, validation-before-mutation behavior, snapshot isolation, diagnostics posture, lowerCamelCase posture keys, shutdown cleanup, and banned runtime surface absence.

Self-checks run through `AssetExecutionGovernanceCoordinator.runSelfChecks()` before the runtime is started.
