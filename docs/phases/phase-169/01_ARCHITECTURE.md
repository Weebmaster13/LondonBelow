# Phase 169 Architecture

The runtime architecture remains a single provider:

`runtimeWorkflowOrchestration`

Phase 169 does not add a second runtime, a second provider, or a new Bootstrap module. The existing `RuntimeWorkflowCoordinator` remains the registered Framework coordinator. `WorkflowIntegrationCoordinator` is a local wrapper for workflow integration operations and delegates to `RuntimeWorkflowOrchestration`.

Workflow integration is constrained to:

- command intent metadata;
- event observation routing metadata;
- query evaluation metadata;
- correlation and causation metadata;
- lifecycle handoff evidence;
- immutable diagnostics and snapshots.

Every integrated workflow step is represented as metadata flowing through existing workflow APIs. Domain systems remain authoritative for their own facts and mutations.
