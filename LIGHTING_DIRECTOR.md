# Lighting Director

The Lighting Director is the server-authoritative foundation for future visibility pressure in London Engine.

It approves or suppresses future lighting requests. It does not mutate Roblox `Lighting`, change Workspace parts, create client remotes, render final effects, or own scare timing.

## Owns

- Dimming approval.
- Flicker approval.
- Shadow pressure approval.
- Visibility pressure approval.
- Safe-room lighting protection.
- Puzzle-room lighting protection.
- Chase-support lighting approval.
- Release lighting approval.
- Lighting pressure state.
- Lighting diagnostics and snapshots.

## Does Not Own

- Physical lighting execution.
- Final art or post-processing.
- Client camera effects.
- Monster AI.
- Chapter 1 content.
- Horror pacing ownership.

## World Intelligence Rules

Lighting requests must resolve World Intelligence context before approval.

Unknown zones deny blackout, major lighting pressure, chase-support lighting, and unfair puzzle disruption.

Safe rooms suppress hostile lighting pressure.

Puzzle rooms protect comprehension and cooperation. Major visibility pressure is deferred unless a future profile and Director approval explicitly allow it.

Affordances are permissions, not actions. `AllowLightDimming` only makes dimming eligible for approval; it never changes lights.

## Request Flow

```text
Observation or Director Request
-> DirectorCoordinator
-> LightingDirector
-> LightingPolicyResolver
-> LightingRequestSelector
-> Approved / Deferred / Rejected with reason
```

Approved decisions are still approval-only. A future Lighting Execution system must perform physical changes after validation and server approval.

## Diagnostics

`LightingDirector.inspect()` exposes:

- recent requests
- approvals
- rejections and suppressions
- policy suppressions
- safe-room suppressions
- puzzle suppressions
- pressure state
- pressure score
- World policy safety summary
- health

## Future Execution Boundary

Future lighting execution must consume approved Lighting Director decisions. It must not invent pacing, bypass World Intelligence, or perform blackouts in unknown zones.

