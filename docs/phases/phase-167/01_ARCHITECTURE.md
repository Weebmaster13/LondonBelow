# Phase 167 Architecture

Runtime systems communicate through contracts, not through each other.

The integration layer sits above the three messaging primitives:

```text
Runtime Event Bus
Runtime Command Bus
Runtime Query Bus
        |
Runtime Messaging Integration
        |
Future runtime consumers
```

The layer owns consumer registration, messaging contracts, dependency mapping, subscription ownership, lifecycle coordination, runtime discovery, diagnostics, snapshots, evidence, metrics, profiler metadata, budgets, inspection, and certification posture metadata.

It does not own gameplay, mutation authority, event storage, query execution, command execution, rendering, AI, dialogue execution, inventory logic, save serialization, remotes, networking, persistence writes, analytics, telemetry, Workspace mutation, or client authority.
