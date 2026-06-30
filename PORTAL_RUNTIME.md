# Cinematic Lobby Portal Runtime

Phase 2.5 adds the server-authoritative chapter-entry portal runtime for London Below. It does not add final UI, real art, monster AI, chapter gameplay, or production place IDs.

The runtime supports the future lobby flow:

1. Players create or join a party.
2. Players enter a black Victorian carriage, fog gate, or old building door portal zone.
3. The server tracks who is inside the portal.
4. The server validates party membership, leader authority, ready state, selected chapter, and full party presence.
5. The portal runs a cinematic countdown and transition.
6. The portal delegates final launch to `MatchmakingService.requestLaunch`.
7. Matchmaking validates again, queues the party, and uses the teleport abstraction.

The portal never teleports directly and never bypasses party or matchmaking validation.

After the Phase 2.5 audit, registered physical portal zones are authoritative when present. Remote boarding remains available only for the current no-zone development foundation through explicit configuration.

## Portal Types

- `VictorianCarriage`: the primary Chapter 1 portal, themed as a black carriage swallowed by fog.
- `FogGate`: a future threshold-style portal where the party walks into thickening fog.
- `ChapterDoor`: a future old building door portal for entering the terrifying main building.

Only `main_carriage` is enabled by default. Other portal definitions exist as future-ready configuration and remain disabled until a physical lobby pass enables them.

## Portal States

- `Idle`: no players are inside.
- `WaitingForParty`: at least one player is inside, but the full party is not present or party truth is incomplete.
- `Boarding`: the party is present, but launch validation is not complete, usually because readiness is missing.
- `ReadyToLaunch`: every party member is inside, ready, and on the selected chapter.
- `Countdown`: cinematic countdown is running.
- `Transitioning`: countdown completed and cinematic transition cues are firing.
- `Launching`: the portal has delegated to matchmaking.
- `Failed`: validation or launch failed.
- `Cooldown`: temporary recovery state after failed launch or cancelled countdown.

Unexpected state jumps are rejected and logged. Failed or cancelled launches enter `Failed` briefly, then `Cooldown`, then refresh into the correct live state.

## Server Responsibilities

`PortalService` owns:

- Portal runtime state.
- Occupant tracking.
- Player-to-portal indexing.
- Portal zone registration hooks.
- Boarding and exit validation.
- Party presence validation.
- Leader validation.
- Ready-state validation.
- Selected chapter validation.
- Countdown scheduling and cancellation.
- Cinematic atmosphere cue emission.
- Safe failure recovery and cooldown.
- Launch attempt tokens that prevent stale delayed tasks from launching.
- Registered zone contact tracking for future physical lobby setup.
- Diagnostics and snapshot hooks.

`PartyService` still owns party truth.

`MatchmakingService` still owns final launch authority.

`QueueService` still owns queued launch state.

`TeleportService` still owns teleport abstraction and production place-id safety.

## Client Responsibilities

`PortalClient.client.lua` is debug-only. It can:

- Request boarding.
- Request exit.
- Request launch.
- Request current portal state.
- Listen for portal state updates.
- Listen for portal errors.
- Listen for atmosphere cues.
- Fail fast with a clear timeout if expected remotes are missing.

Future UI should wire these events into:

- Board prompt.
- Party status.
- Countdown text.
- Transition fade.
- Carriage door close.
- Fog swell.
- Heartbeat.
- Whisper.

The client never owns portal state, party state, readiness, countdown authority, or launch authority.

## Remotes

All remotes are created by `RemoteManager` under namespace `LobbyPortal`, version `1`.

Client to server:

- `RequestBoard_v1`: `{ portalId: string? }`
- `RequestExit_v1`: `{ portalId: string? }`
- `RequestLaunch_v1`: `{ portalId: string? }`
- `RequestState_v1`: `{}`

Server to client:

- `PortalStateUpdated_v1`: `{ ok: boolean, portal: PortalState? , portals: { [string]: PortalState }? }`
- `PortalError_v1`: `{ ok: false, code: string, message: string, state: PortalState?, data: any? }`
- `PortalAtmosphereCue_v1`: `{ portalId: string, portalType: string, cue: string, data: any? }`

Remote calls are rate-limited by `PortalConfig.RemoteRateLimitPerSecond`.

## Cinematic Hooks

The runtime exposes atmosphere cues but does not build final art yet:

- `CarriageLanternFlicker`
- `DoorClosing`
- `FogThickening`
- `HorseSound`
- `Heartbeat`
- `Whisper`
- `ScreenFade`
- `RainMuffling`
- `DistantMonsterGlimpse`
- `ChapterTransition`

Future client effects should treat these as timing hooks, not authority. If a cue is missed, gameplay state must still remain correct.

## Failure Handling

Portal launches can fail because:

- The portal is disabled.
- The portal is full.
- The player is not in the portal.
- The player is not in a party.
- The player is not the leader.
- The portal is assigned to another party.
- The selected chapter does not match the portal.
- Not every party member is inside the portal.
- Not every party member is ready.
- Countdown was cancelled by exit, disconnect, or party change.
- Matchmaking rejects launch.
- Teleport configuration is missing or teleport fails.

Failures are returned as structured codes and messages. Failed or cancelled countdowns enter `Failed`, then `Cooldown`, and then refresh back to the correct state.

Additional audit hardening codes include:

- `ZONE_REQUIRED`
- `STATE_CONFLICT`

## Physical Lobby Setup

Future Roblox Studio setup should create physical zone parts for each portal:

- Place non-visible trigger parts inside the carriage, fog gate, or doorway.
- Give each trigger a stable portal id matching `SharedPortalConfig.Portals`.
- Register each trigger with `PortalService.registerPortalZone(portalId, zonePart)` from a future lobby bootstrapper.
- Keep visual models, lights, fog, sounds, and prompt UI separate from the authority trigger.
- Treat `Touched` and `TouchEnded` as a foundation API, not the final production volume solution. A future zone library can call `playerEnteredZone` and `playerExitedZone` directly.

The physical portal is presentation. `PortalService` remains the server authority.

## Current Limitations

- The current portal client is debug-only.
- Remote boarding without a registered zone is enabled only for current development convenience.
- `TouchEnded` support is provided for future Studio zones, but a production lobby should replace it with a more reliable zone volume library.
- The enabled `main_carriage` portal points to Chapter 1 configuration, but real place IDs are still intentionally absent.
- No final art, UI, chapter content, or monster systems are included.
