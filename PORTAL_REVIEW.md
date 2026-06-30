# Cinematic Lobby Portal Runtime Audit

## Audit Summary

Phase 2.5 was audited as a launch-readiness pass for a multiplayer Roblox horror lobby. The portal runtime remains a foundation layer only: no monster AI, chapter gameplay, final UI, final art, or production teleport place IDs were added.

The audit confirmed the most important server-authority rule: the portal may stage cinematic boarding and countdown, but final launch still goes through `MatchmakingService.requestLaunch`. The portal does not teleport directly and cannot bypass party validation.

## Files Reviewed

- `src/ServerScriptService/Lobby/Portals/PortalService.lua`
- `src/ServerScriptService/Lobby/Portals/PortalConfig.lua`
- `src/ServerScriptService/Lobby/Portals/PortalTypes.lua`
- `src/ReplicatedStorage/Lobby/LobbyConfig/SharedPortalConfig.lua`
- `src/ReplicatedStorage/Lobby/PortalRemotes/PortalRemoteNames.lua`
- `src/StarterPlayer/StarterPlayerScripts/ClientUI/Menus/PortalClient.client.lua`
- `src/ServerScriptService/Lobby/LobbyService.lua`
- `src/ServerScriptService/Lobby/Matchmaking/MatchmakingService.lua`
- `src/ServerScriptService/Lobby/Queues/QueueService.lua`
- `src/ServerScriptService/Lobby/Teleporting/TeleportService.lua`
- `src/ServerScriptService/Core/Bootstrap.server.lua`
- `src/ServerScriptService/Core/RemoteManager.lua`
- `src/ServerScriptService/Core/Scheduler.lua`
- `src/ServerScriptService/Core/Diagnostics.lua`
- `src/ServerScriptService/Core/SnapshotManager.lua`
- `default.project.json`
- `PORTAL_RUNTIME.md`

## Issues Found

- Debug client remotes used unbounded `WaitForChild`, which could hang silently if server remotes failed to initialize.
- Remote boarding could become an exploit once physical portal zones exist, because a client request alone could mark the player as boarded.
- Cinematic transition tasks were scheduled but not tracked, so cancelled launches could leave delayed atmosphere callbacks alive.
- Delayed launch handoff needed a stronger stale-attempt guard so an old transition could not launch after a failure or recovery.
- Countdown cancellation and transition failure paths could skip a visible `Failed` state by going directly to cooldown.
- Portal state transitions were implicit, which made future changes more likely to introduce invalid jumps.
- Registered physical zone setup needed clearer rules around `Touched` and `TouchEnded` unreliability.

## Fixes Made

- Added client remote wait timeouts with clear errors in `PortalClient.client.lua`.
- Added `ZoneRequired` and `StateConflict` structured portal error codes.
- Added registered-zone contact tracking to `PortalService`.
- Made registered physical zones authoritative when present.
- Kept remote boarding available only for the current no-zone development foundation through explicit config.
- Added launch attempt tokens to reject stale countdown or transition tasks.
- Added tracked transition handles and cleanup for cinematic cue and launch-delay tasks.
- Added a single `failPortal` recovery path: cancel countdown, cancel transition work, enter `Failed`, then enter `Cooldown`, then refresh.
- Added an explicit allowed transition graph for portal states.
- Added `stateEnteredAt` and `launchToken` to serialized portal diagnostics.
- Documented the new behavior in `PORTAL_RUNTIME.md`.

## Server Authority Rules

- Clients may request boarding, exit, launch, and state.
- Clients never decide portal occupants, party membership, readiness, selected chapter, countdown validity, queue state, or teleport state.
- If registered zones exist, a player must be inside the server-tracked zone before boarding succeeds.
- The party leader is the only player who can request launch.
- Every party member must be inside the same portal.
- Every party member must be ready.
- The party selected chapter must match the portal chapter.
- Final launch must call `MatchmakingService.requestLaunch`.
- Teleporting remains isolated behind `TeleportService`.

## State Machine

Allowed flow:

- `Idle` -> `WaitingForParty`, `Boarding`, `ReadyToLaunch`, `Failed`, `Cooldown`
- `WaitingForParty` -> `Idle`, `Boarding`, `ReadyToLaunch`, `Failed`, `Cooldown`
- `Boarding` -> `Idle`, `WaitingForParty`, `ReadyToLaunch`, `Failed`, `Cooldown`
- `ReadyToLaunch` -> `Idle`, `WaitingForParty`, `Boarding`, `Countdown`, `Failed`, `Cooldown`
- `Countdown` -> `Transitioning`, `Failed`
- `Transitioning` -> `Launching`, `Failed`
- `Launching` -> `Launching`, `Failed`
- `Failed` -> `Cooldown`, `Idle`
- `Cooldown` -> `Idle`, `WaitingForParty`, `Boarding`, `ReadyToLaunch`, `Failed`

Unexpected transitions are rejected and logged.

## Countdown Cancellation Rules

Countdown cancels if:

- The leader leaves.
- Any party member leaves the portal.
- Any party member disconnects.
- The party changes readiness.
- The party selected chapter changes.
- The party is destroyed.
- Validation fails before transition.
- A newer launch attempt token replaces the active attempt.

Cancellation enters `Failed`, holds briefly for clients to display failure, then enters `Cooldown`.

## Disconnect Handling

`PortalService` listens to `Players.PlayerRemoving`. If a disconnecting player is inside a portal, they are removed from occupant state. If the portal is counting down or transitioning, the active launch attempt fails safely and recovers through cooldown.

`PartyService` also handles disconnects. Portal validation rechecks party truth on each countdown tick and again immediately before matchmaking handoff, so either service order is safe.

## Physical Studio Setup Rules

- Create one or more invisible trigger parts for each portal.
- Keep visual carriage, fog, door, lights, and sound objects separate from authority triggers.
- Register triggers with `PortalService.registerPortalZone(portalId, zonePart)`.
- Use stable portal IDs from `SharedPortalConfig.Portals`.
- Do not let client UI directly assert zone presence.
- Treat `TouchEnded` as imperfect. For final production, consider replacing trigger parts with a robust zone volume system while keeping the same `playerEnteredZone` and `playerExitedZone` server APIs.
- Once physical zones exist, registered zone tracking becomes the boarding authority.

## Future UI Integration Rules

- UI should render `PortalStateUpdated_v1`.
- UI should display structured `PortalError_v1` messages.
- UI should treat `PortalAtmosphereCue_v1` as presentation timing only.
- UI must not assume countdown success.
- UI must handle `Failed` and `Cooldown`.
- UI must handle remotes timing out during broken Studio setup.
- Board prompts should call `RequestBoard_v1`, but the server still decides whether the player is inside the zone.

## Testing Checklist

Solo:

- Create or auto-create solo party.
- Board `main_carriage`.
- Ready solo player.
- Launch countdown.
- Verify transition cues.
- Verify teleport-disabled failure recovers to cooldown.

Two players:

- Leader and member join same party.
- Member boards first, then leader boards.
- Verify launch is rejected until both are ready.
- Verify launch is rejected if only one player is inside.
- Verify member cannot launch.
- Verify leader launch recovers if member exits during countdown.

Three players:

- Verify all three must be inside and ready.
- Change selected chapter during countdown and verify cancellation.
- Disconnect one member during countdown and verify `Failed` then `Cooldown`.
- Verify stale transition does not launch.

Four players:

- Verify max party size boards correctly.
- Verify fifth player is rejected by party or portal capacity.
- Verify wrong-party player cannot reserve or enter an occupied portal.
- Verify leader leaving transfers party leadership but cancels active countdown.
- Verify double launch requests return `LAUNCH_IN_PROGRESS` or state conflict.

## Remaining Risks

- `TouchEnded` is not reliable enough for final production by itself. The server API is ready for a future zone library.
- Current debug remote boarding is intentionally allowed when no physical zones are registered. This must remain disabled or irrelevant once real zones are registered.
- Teleport remains disabled until real chapter place IDs are configured.
- Final UI must be built later and must not trust local state.
- Load testing with real Roblox clients is still needed after physical lobby geometry exists.
