# Phase 2.5 Portal Test Plan

Use this checklist to verify the physical `main_carriage` portal prototype in Roblox Studio. This plan tests runtime behavior only. It does not test final UI, final art, chapter gameplay, or monster systems.

## Before Testing

1. Sync the project with Rojo.
2. Confirm `Workspace/Portals/main_carriage` exists.
3. Confirm `main_carriage` has `PortalId = "main_carriage"`.
4. Confirm the part is `Anchored`, `CanTouch`, and invisible.
5. Start a Studio server test with the required number of players.
6. Open Developer Console for server and clients.

## Solo Boarding

1. Start Play Solo.
2. Walk into the `main_carriage` zone.
3. Confirm the server does not crash.
4. Confirm `PortalClient` receives a portal state update.
5. Confirm the player appears as an occupant.
6. Create or auto-create a solo party.
7. Set the solo player ready through the debug lobby flow.
8. Confirm portal state reaches `ReadyToLaunch`.

Expected result:

- Solo player is tracked by the server.
- Client only receives state; it does not own state.
- Portal does not launch until leader requests launch and party validation passes.

## Solo Countdown

1. Complete Solo Boarding.
2. Request portal launch through the debug client hook or future temporary test button.
3. Confirm state changes to `Countdown`.
4. Confirm countdown ticks appear in debug output.
5. Confirm atmosphere cues are printed.
6. Wait for transition.

Expected result:

- `Countdown` progresses.
- `Transitioning` begins.
- `Launching` delegates to matchmaking.
- Teleport failure or disabled config recovers safely.

## Failed Teleport Recovery

1. Keep Chapter 1 place ID unset.
2. Complete Solo Countdown.
3. Let the portal reach launch.
4. Confirm teleport disabled/failure is logged.
5. Confirm portal enters `Failed`.
6. Confirm portal enters `Cooldown`.
7. Wait for cooldown to complete.
8. Confirm portal returns to `Idle`, `WaitingForParty`, `Boarding`, or `ReadyToLaunch` based on current occupants and party state.

Expected result:

- No server crash.
- No stuck queue.
- No stuck countdown.
- No permanent `Failed` state.

## Two-Player Party Boarding

1. Start a local server with 2 players.
2. Player 1 creates a party.
3. Player 2 joins the party.
4. Player 1 selects Chapter 1.
5. Player 1 enters `main_carriage`.
6. Confirm portal waits for the party.
7. Player 2 enters `main_carriage`.
8. Both players ready up.

Expected result:

- Portal does not launch with only one party member inside.
- Portal reaches `ReadyToLaunch` only when both members are inside and ready.
- Player 2 cannot launch if Player 1 is leader.

## Two-Player Countdown Cancel

1. Complete Two-Player Party Boarding.
2. Leader requests launch.
3. During countdown, Player 2 walks out of the zone.

Expected result:

- Countdown cancels.
- Portal enters `Failed`.
- Portal enters `Cooldown`.
- Portal recovers after cooldown.
- No delayed transition launches afterward.

## Disconnect During Countdown

1. Start a local server with at least 2 players.
2. Board and ready the party.
3. Leader starts countdown.
4. Stop one client or disconnect one player during countdown.

Expected result:

- Player is removed from portal occupant state.
- Countdown cancels.
- Portal enters `Failed`, then `Cooldown`.
- Remaining player receives state update.
- PartyService handles membership cleanup.

## Leader Leaving

1. Start a local server with 2 or more players.
2. Leader creates party and boards everyone.
3. Everyone readies.
4. Leader starts countdown.
5. Leader leaves the portal or disconnects.

Expected result:

- Active countdown cancels.
- Portal enters `Failed`, then `Cooldown`.
- PartyService may transfer leadership, but the old launch attempt does not continue.
- New leader must request a new launch after recovery.

## Three-Player Party

1. Start 3-player local server.
2. Create one party with all 3 players.
3. Board only 2 players.
4. Ready all players.
5. Attempt launch.

Expected result:

- Launch is rejected because one party member is missing from the portal.

Then:

1. Board the third player.
2. Request launch.
3. Change readiness or selected chapter during countdown.

Expected result:

- Countdown cancels and recovers.

## Four-Player Party Behavior

1. Start 4-player local server.
2. Create a party of 4.
3. Board all 4 players.
4. Ready all 4 players.
5. Leader requests launch.

Expected result:

- All 4 occupants are tracked.
- Portal reaches `Countdown`.
- Transition attempts matchmaking.
- Teleport disabled/failure recovers safely if no place ID exists.

## Wrong Party / Capacity Check

1. With a 4-player party occupying `main_carriage`, try to board another player from a different party in a larger server test.

Expected result:

- Wrong-party player is rejected with a party mismatch or capacity failure.
- Existing party state is not changed.

## Double Launch Check

1. Board and ready a party.
2. Leader sends launch request multiple times quickly.

Expected result:

- First request starts countdown.
- Later requests return launch-in-progress or state-conflict behavior.
- Only one transition attempts matchmaking.

## Developer Console Signals

Look for:

- `PortalZoneBinder` successful binding log.
- `PortalService` state transition logs.
- `PortalClient` state updates.
- `PortalClient` atmosphere cues.
- Teleport disabled warning when place IDs are missing.

Investigate immediately if:

- The client waits forever for remotes.
- The server throws during bootstrap.
- The portal remains stuck in `Countdown`, `Transitioning`, `Failed`, or `Cooldown`.
- A non-leader can launch.
- A player outside the zone can board after zones are registered.
