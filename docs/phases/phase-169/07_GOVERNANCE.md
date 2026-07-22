# Governance

Phase 169 adds the `Runtime Workflow Integration Hardening` Governance contract.

The contract belongs to Core and depends on:

- Core Runtime;
- Runtime Event Bus and Cross-Runtime Messaging Foundation;
- Runtime Command Bus and Deterministic Command Processing;
- Runtime Query Bus and Read-Only Access Foundation;
- Runtime Messaging Integration and Consumer Foundation;
- Runtime Workflow and Process Orchestration Foundation.

The snapshot provider remains `runtimeWorkflowOrchestration`.

The contract explicitly prohibits gameplay authority, command execution, event publication, query execution, networking, remotes, persistence writes, analytics, telemetry, client authority, and Workspace mutation.
