# Portal Runtime Refactor Review

## Summary

The Portal Runtime refactor preserved the Phase 2.5 behavior while splitting `PortalService.lua` into smaller focused modules. `PortalService` remains the orchestrator for lifecycle, remotes, EventBus wiring, diagnostics, snapshots, and the public API.

The split did not intentionally change remotes, client payloads, launch flow, countdown behavior, teleport behavior, portal state names, or server authority rules.

## Module Responsibilities

- `PortalService.lua`: orchestrates remotes, lifecycle, EventBus subscriptions, public service methods, diagnostics, snapshots, and cross-module coordination.
- `PortalStateMachine.lua`: owns allowed portal state transitions and transition logging.
- `PortalOccupants.lua`: owns portal lookup helpers, occupant counts, serialized portal state, and runtime portal table initialization.
- `PortalCountdown.lua`: owns countdown, transition scheduling, launch tokens, failure recovery, cooldowns, and scheduled task cleanup.
- `PortalZoneTracker.lua`: owns physical zone contact counts, zone `Touched` / `TouchEnded` connections, zone inspection, and zone cleanup.
- `PortalValidator.lua`: owns party presence, leader, readiness, chapter, cooldown, and launch validation.
- `PortalAtmosphere.lua`: owns atmosphere cue payloads, per-occupant client dispatch, and atmosphere EventBus publishing.
- `PortalZoneBinder.lua`: discovers `Workspace/Portals` parts and registers zones with `PortalService`.

## Behavior Preservation Check

- Remote namespace remains `LobbyPortal`.
- Remote names remain `RequestBoard`, `RequestExit`, `RequestLaunch`, `RequestState`, `PortalStateUpdated`, `PortalError`, and `PortalAtmosphereCue`.
- Final launch still delegates to `MatchmakingService.requestLaunch`.
- Portal runtime still does not call `TeleportService` directly.
- Party truth still comes from `PartyService`.
- Countdown cancellation still enters failure recovery through `Failed` and `Cooldown`.
- Registered physical zones still become authoritative when present.
- Missing physical zones still do not crash the server.

## Circular Require Check

No circular require path was introduced.

`PortalService` requires the focused portal modules. The focused modules require only core services, party/matchmaking services where needed, config/types, and helper modules. None of the focused modules require `PortalService`.

## Cleanup Check

- `PortalService.shutdown()` disconnects remote/event connections.
- `PortalCountdown.cleanup()` cancels countdown, cooldown, and transition task handles.
- `PortalZoneTracker.cleanup()` disconnects zone connections and clears contact/registration tables.
- EventBus disconnect functions are still stored and disconnected by `PortalService`.

## Server Authority Check

- Clients may request portal actions only through RemoteManager-created remotes.
- Remote calls are still rate-limited by `PortalConfig.RemoteRateLimitPerSecond`.
- Clients cannot set occupants directly.
- Clients cannot fake party membership or readiness.
- Clients cannot launch unless the server validates portal presence, party leadership, party readiness, selected chapter, and full party presence.
- If physical zones are registered, boarding requires server-tracked zone contact.

## Remaining Risks

- Roblox `Touched` and `TouchEnded` remain prototype-grade zone signals. Final production should still use a robust zone volume system that calls the same server APIs.
- Behavior parity was verified through static review and tooling, not through live multi-client Studio simulation in this pass.
- Teleport remains intentionally disabled until chapter place IDs are configured.
- Final UI integration still needs live Studio testing against portal state updates, errors, and atmosphere cues.
