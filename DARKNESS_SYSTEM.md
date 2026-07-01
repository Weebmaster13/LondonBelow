# Darkness System

The Darkness System is the reusable server-authoritative gameplay truth layer for darkness exposure in London Engine.

It does not create final lighting effects, final audio, final scares, Chapter 1 content, Monster AI, or client-owned fear state.

## Owns

- Darkness entered and exited truth.
- Darkness exposure score.
- Exposure increase tracking.
- Safe-room darkness protection.
- Puzzle-room readability protection.
- Darkness observations.
- Director requests for future Lighting, Audio, and Environment pressure.
- Diagnostics and snapshots.

## Client Boundary

Clients do not report trusted darkness truth.

Client-owned zone or exposure claims are not accepted. Darkness truth must be created by trusted server systems such as future zone binders, chapter logic, or server-owned lighting volumes.

Future server-owned zone, lighting, or chapter systems should call:

- `DarknessService.enterDarkness(player, context)`
- `DarknessService.exitDarkness(player)`
- `DarknessService.updateExposure(player, context)`

## Observation Output

The system emits:

- `Darkness.Entered`
- `Darkness.Exited`
- `Darkness.ExposureIncreased`
- `Darkness.ProtectedZone`

## World Intelligence Rules

Unknown zones are protected by default.

Safe rooms suppress hostile darkness pressure.

Puzzle rooms protect readability, comprehension, and team cooperation.

## Director Integration

DarknessService may request future Lighting, Audio, and Environment Director approvals after exposure crosses the configured threshold. These requests are approval-only and do not mutate Workspace, Roblox Lighting, or audio playback.

Exposure observations and Director requests are throttled. Failed, deferred, rejected, protected, or suppressed Director paths do not change darkness truth.

## Future Work

Future physical zone binders can feed DarknessService from server-owned triggers. They must never trust client-owned darkness claims.
