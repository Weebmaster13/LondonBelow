# Director Coordinator

`DirectorCoordinator` is the server-only lifecycle and routing owner for the Director Ecosystem at `ServerScriptService/Core/Directors/DirectorCoordinator.lua`.

It owns:

- Director discovery and registration.
- Director startup and shutdown order.
- Contract validation through `DirectorContract`.
- Observation routing from the Observation Engine.
- Pending request ownership and expiration.
- Request submission through `DirectorRouter`.
- Approval, rejection, deferral, modification, expiration, and cancellation records.
- Decision traces through `DirectorDecisionTrace`.
- Diagnostics and snapshots.
- Self-checks for valid routing, unknown Director rejection, expiration, cancellation, traces, and diagnostics.

It does not own gameplay, Monster AI, final audio, final lighting, final UI, art, or chapter content.

## Failure Isolation

Director observation calls and lifecycle calls are wrapped with protected calls. If one Director fails, the Coordinator records the failure, publishes diagnostics, and keeps the rest of the ecosystem alive.

## Request Resolution

Directors submit structured requests. The Coordinator stores the request as pending, routes it, records the final approval, then removes it from pending state. A future `RequestMonsterReveal` can be deferred while a lower-risk `RequestLightingChange` is approved, but neither result directly executes gameplay.

## Diagnostics

Coordinator diagnostics include registered Directors, missing required Directors, Director health, capabilities, pending request count, recent approvals, metrics, recent failures, decision traces, and conflict resolver state.
