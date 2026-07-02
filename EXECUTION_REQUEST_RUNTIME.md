# Execution Request Runtime

`ExecutionRequestRuntime` stores normalized execution request schemas. It never executes gameplay.

## Request Shape

Each request contains:

- `executionId`
- `requester`
- `sourceSystem`
- `executionType`
- `priority`
- `createdAt`
- `expiresAt`
- `dependencies`
- `approvals`
- `metadata`
- `reason`
- `context`

## Rules

- `executionId`, `requester`, `sourceSystem`, and `executionType` are required.
- Requests are deep-copied before storage.
- Duplicate execution ids reject.
- Unsafe payloads reject before state changes.
- Request history is bounded.

## Boundary

Requests are schemas only. They may describe a future approved intent, but they must not contain Roblox Instances, Workspace references, movement commands, damage, animations, remotes, UI, Audio, Lighting, Chapter content, story, dialogue, cutscenes, Monster AI ownership, or horror pacing ownership.
