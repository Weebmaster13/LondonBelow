# Director Approvals

Approvals are structured responses created by `ServerScriptService/Core/Directors/DirectorApproval.lua`.

Required approval fields:

- `requestId`
- `status`
- `reason`
- `decidedBy`
- `decidedAt`
- `modifiedRequest`
- `diagnostics`

## Statuses

- `Approved`: the request may proceed to a future execution system.
- `Rejected`: the request is invalid, unsafe, unknown, or not allowed.
- `Deferred`: the request may be reconsidered later.
- `Modified`: the request is approved only with changed parameters.
- `Expired`: the request timed out before a safe decision.
- `Cancelled`: the Coordinator or source cancelled the request.

## Rules

- Every decision needs a human-readable reason.
- No approval should imply direct gameplay execution.
- `modifiedRequest` must preserve the original `requestId`.
- Diagnostics metadata should include enough context to debug future pacing or authority issues without trusting the client.
- Target approvals are validated by `DirectorRouter` before being accepted into decision history.
