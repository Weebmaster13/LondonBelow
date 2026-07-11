# Execution Request Runtime

`ExecutionRequestRuntime` stores normalized execution request schemas for the Phase 91 Asset Execution Runtime. It never executes gameplay or assets.

## Request Shape

Each request contains:

- `requestId`
- `runtimeId`
- `requestKind`
- `requestStatus`
- `requestedBy`
- `evidence`
- `tags`
- `metadata`

## Rules

- `requestId`, `runtimeId`, `requestKind`, `requestStatus`, and `requestedBy` are required.
- The parent `ExecutionRuntime` must already exist before registration.
- Requests are deep-copied before storage.
- Duplicate request ids reject globally.
- Unsupported fields reject.
- Unsafe payloads reject before state changes.

## Boundary

Requests are schemas only. They may describe future execution intent, but they are not commands and do not route, dispatch, queue, schedule, orchestrate, load assets, spawn assets, play assets, mutate Workspace, create remotes, grant client authority, execute gameplay, execute Presentation, execute Save, or add Chapter content.
