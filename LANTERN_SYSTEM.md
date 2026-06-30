# Lantern System

The Lantern System is the reusable server-authoritative gameplay truth layer for lantern state in London Engine.

It does not create final lighting effects, final UI, final audio, final scares, Chapter 1 content, or Monster AI.

## Owns

- Lantern equipped and unequipped truth.
- Lantern on and off truth.
- Battery/fuel hooks.
- Low-battery observation.
- Overuse tracking.
- Lantern observations.
- Director requests for future Lighting and Audio presentation pressure.
- Presentation-hook remotes.
- Diagnostics and snapshots.

## Client Boundary

Clients may request lantern on/off only through RemoteManager.

Clients do not own equipped truth, battery truth, overuse truth, darkness truth, fear truth, or Director approvals.

The current remote namespace is `Lantern`. It exposes:

- `RequestToggle`: client-to-server request for on/off only.
- `StateUpdated`: server-to-client presentation hook.
- `RequestResult`: server-to-client request result.

## Observation Output

The system emits:

- `Lantern.Equipped`
- `Lantern.Unequipped`
- `Lantern.TurnedOn`
- `Lantern.TurnedOff`
- `Lantern.LowBattery`
- `Lantern.Overused`

## Director Integration

LanternService may request future Lighting Director and Audio Director approvals. These are approval-only requests. The Directors do not create final effects, and LanternService does not mutate Roblox Lighting or play audio.

## Protection Rules

Unknown zones remain conservative through World Intelligence.

Safe rooms and puzzle-protected rooms mark lantern pressure as protected. Future hostile sensory pressure should not be generated there.

## Future Work

Future inventory or interaction systems should call `LanternService.equip()` and `LanternService.unequip()` from trusted server code. They must not let clients directly set equipped truth.

