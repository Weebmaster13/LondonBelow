# Monster AI Self-Checks

Phase 17 self-checks are deterministic certification scenarios for the Monster AI execution foundation.

## Covered Conditions

- Malformed monster definitions reject.
- Monster AI registration succeeds.
- Duplicate monster registration rejects.
- Approved intent is accepted.
- Duplicate intent IDs reject.
- Missing Director approval rejects.
- Unsupported intent kinds reject.
- Expired intents reject.
- Unknown monsters reject.
- Nested unsafe execution fields reject.
- Instance-like payload fields reject without creating Roblox Instances.
- Cyclic payloads reject through the service path.
- Cyclic serialization rejects.
- Unsafe runtime values reject through serialization and service validation.
- Oversized payloads reject.
- Dry-run records are created for accepted intent.
- Diagnostics are read-only copies.
- Snapshot output is isolated.
- Runtime histories remain bounded.
- Shutdown cleanup clears state.
- No Workspace mutation, movement, pathfinding, navigation execution, remotes, client authority, damage, attacks, animation, Audio, Lighting, UI, or final behavior exists.

## Safety Boundary

Self-checks clear the Monster AI registry and state. `MonsterAIService.runSelfChecks` refuses to run after the service has started and suppresses Observation Engine emission while certification is active.

## Future Self-Checks

Future phases may add adapter contract checks, path planner mock checks, animation adapter dry-run checks, or multi-monster coordination checks. They must stay server-authoritative and must not mutate Workspace unless a later approved execution phase explicitly allows it.