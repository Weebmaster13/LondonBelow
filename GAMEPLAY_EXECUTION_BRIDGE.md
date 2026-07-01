# Gameplay Execution Bridge

Phase 14 creates the safe execution boundary between server-owned gameplay truth and future physical or presentation adapters.

Gameplay systems own truth. The Execution Bridge does not. It accepts validated execution requests and routes them to opt-in adapters later. By default the bridge runs in `DryRun`, and physical mutation is disabled.

## Why It Exists

Without this bridge, future doors, drawers, puzzle panels, objectives, and environmental objects would be tempted to move parts, play effects, or animate directly from gameplay code. That creates one-off scripts and mixes truth with presentation.

The bridge preserves the London Engine flow:

```text
Gameplay truth
-> Observation fact
-> Director approval when needed
-> Execution request
-> Adapter applies future physical/presentation hook
```

## Request Shape

Execution requests contain:

- `executionId`
- `sourceSystem`
- `targetObjectId`
- `executionKind`
- `requestedState`
- `approvedBy`
- `approvalId`
- `gameplayFactId`
- `priority`
- `createdAt`
- `expiresAt`
- `payload`
- `metadata`
- `tags`

## Statuses

Requests move through `Pending`, `Validated`, `Rejected`, `Deferred`, `Applied`, `Failed`, `Cancelled`, and `Expired`.

`Applied` in dry-run mode means the request passed the boundary without physical mutation.

## Adapter Contract

Future adapters must implement:

- `canApply(request)`
- `apply(request)`
- `rollback(request)`
- `getHealth()`
- `getDiagnostics()`
- `describe()`

Adapters register with `GameplayExecutionService.registerAdapter(kind, adapter)`.

No real Workspace adapters are implemented in Phase 14.

## Production Hardening

The production audit added bounded execution record history, safer cancellation lock release, duplicate rejection that does not mutate the original queued record, adapter `pcall` isolation, stronger tag/request validation, missing-adapter deferral for future enabled mode, and expanded diagnostics/self-check evidence.

## Intentional Boundaries

- No client remotes.
- No final UI, art, sounds, scares, or Monster AI.
- No Chapter 1 content.
- No direct random Workspace mutation.
- No gameplay truth mutation inside execution.
- No physical mutation unless future configuration and adapters opt in explicitly.
