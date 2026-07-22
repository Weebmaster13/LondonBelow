# Phase 168 Architecture

The workflow layer coordinates existing runtime consumers through the Runtime Messaging Architecture.

```text
Runtime Workflow Layer
        |
Runtime Messaging Integration
        |
Commands / Events / Queries
```

A workflow may request commands, observe events, issue queries, evaluate immutable results, and transition deterministic state. It never invokes consumers directly, publishes events directly, executes commands directly, modifies query results, or accesses subsystem internals.

The layer owns workflow definitions, workflow registration, workflow instances, lifecycle, scheduling metadata, transition metadata, waits, timeouts, retries, cancellation, compensation metadata, diagnostics, snapshots, evidence, metrics, profiler metadata, inspection, budgets, and certification posture.
