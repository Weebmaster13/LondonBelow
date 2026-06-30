# Lobby Runtime

Phase 2 introduces the server-authoritative lobby foundation for London Below. It is not final UI, final matchmaking, final teleport production configuration, monster AI, or chapter gameplay.

## Party Lifecycle

1. A player creates a party or launches solo, which creates a one-player party.
2. Other players may join if the party exists, is unlocked, is not full, and is not launching.
3. The leader may select a chapter, lock or unlock the party, kick members, and transfer leadership.
4. Members may ready or unready.
5. All members must be ready before launch.
6. A launch request queues the party and marks it as launching.
7. Teleporting succeeds, fails, or is safely disabled if the chapter place id is missing.
8. If a player leaves or disconnects, PartyService removes them.
9. If the leader leaves, leadership transfers to the next member.
10. If a party becomes empty, it is destroyed.

The server owns all party truth. Clients only request actions and render state updates.

## Server Responsibilities

- Own party membership, leader, ready state, selected chapter, locked state, and launching state.
- Prevent duplicate party membership.
- Validate every request.
- Rate-limit lobby remotes through RemoteManager.
- Transfer leaders when needed.
- Destroy empty parties.
- Validate launch readiness, party size, chapter selection, cooldown, and double-launch prevention.
- Queue launch attempts.
- Safely handle missing teleport configuration.
- Log all important state changes and failures.

## Client Responsibilities

- Request party creation, ready toggle, leaving, and launch.
- Receive party state updates.
- Receive lobby errors.
- Receive launch state updates.
- Render or print debug state.

The current `LobbyClient.client.lua` is intentionally a debug client, not final polished UI.

## Remote Contracts

All remotes are created through `RemoteManager` under namespace `Lobby`, version `1`.

Client to server:

- `CreateParty_v1`: `{}`.
- `JoinParty_v1`: `{ partyId: string }`.
- `LeaveParty_v1`: `{}`.
- `KickMember_v1`: `{ targetUserId: number }`.
- `TransferLeader_v1`: `{ targetUserId: number }`.
- `SetReady_v1`: `{ ready: boolean }`.
- `SelectChapter_v1`: `{ chapterId: string }`.
- `SetLocked_v1`: `{ locked: boolean }`.
- `RequestLaunch_v1`: `{}`.
- `RequestState_v1`: `{}`.

Server to client:

- `PartyStateUpdated_v1`: `{ ok: boolean, party: PartyState? }`.
- `LobbyError_v1`: `{ ok: false, code: string, message: string, data: any?, party: PartyState? }`.
- `LaunchStateUpdated_v1`: `{ ok: boolean, code: string, message: string, data: any?, party: PartyState? }`.

## Launch Flow

`MatchmakingService` validates the leader request, readiness, party size, chapter selection, launch cooldown, and queue state.

`QueueService` records the queued party and exposes queue state.

`TeleportService` is a safe abstraction over Roblox teleport APIs. It supports future reserved server flow, but currently returns a clear disabled result if `ChapterPlaceIds` are not configured.

## Failure Handling

Every failure returns a structured code and message. Examples:

- `ALREADY_IN_PARTY`
- `PARTY_NOT_FOUND`
- `PARTY_FULL`
- `PARTY_LOCKED`
- `NOT_LEADER`
- `NOT_READY`
- `INVALID_CHAPTER`
- `LAUNCH_IN_PROGRESS`
- `LAUNCH_COOLDOWN`
- `TELEPORT_DISABLED`
- `TELEPORT_FAILED`

Teleport configuration failures must never crash the server.

## Future UI Plan

The final UI should replace debug prints with:

- Party member cards.
- Leader controls.
- Ready buttons.
- Chapter selection.
- Party lock state.
- Clear error banners.
- Launch countdown and transition state.
- Controller, keyboard, mouse, and mobile navigation.

The client must still never own party truth.

## Future Carriage/Fog Gate/Chapter Portal Plan

The future physical lobby should support atmospheric launch points:

- Victorian carriage: party boards together before teleport.
- Fog gate: party walks into a fog threshold when ready.
- Main building door: party enters a chapter through a locked or opening door.

These should trigger server-side launch requests and use the same PartyService and MatchmakingService validation. The physical portal is presentation and interaction; it is not the authority.

## Self-Checks

`PartyService.runSelfChecks()` validates:

- Party creation.
- Member join and leave.
- Leader transfer.
- Ready validation.
- Duplicate membership prevention.
- Launch validation.

`LobbyService.initialize()` runs self-checks before reporting startup success.
