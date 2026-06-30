# Director Requests

Directors communicate through structured requests created by `ServerScriptService/Core/Directors/DirectorRequest.lua`.

Required request fields:

- `requestId`
- `sourceDirector`
- `targetDirector`
- `requestKind`
- `priority`
- `reason`
- `createdAt`
- `expiresAt`
- `supportingObservationIds`
- `context`
- `metadata`
- `requiresApproval`
- `conflictGroup`
- `tags`

## Request Kinds

Examples reserved for future systems:

- `RequestMonsterReveal`
- `RequestMonsterAttack`
- `RequestLightingChange`
- `RequestMusicState`
- `RequestEnvironmentReaction`
- `RequestNarrativeBeat`
- `RequestPuzzleHint`
- `RequestCheckpoint`
- `RequestPerformanceBudget`

Requests are permission checks, not execution commands. A request may become an instruction to an execution system only after an approval path allows it.

## Expiration

Every request has `expiresAt`. The Coordinator rejects already-expired requests and sweeps pending expired requests on a Scheduler interval. Expiration is required so future Directors cannot leave critical game decisions stuck forever.

## Conflict Groups

`conflictGroup` is optional but should be used when multiple Directors may compete over the same tension, lighting, audio, monster, or performance budget. Conflict resolution is deterministic and traceable.
