# Phase 2.5 Portal Studio Setup

This plan makes the Cinematic Lobby Portal Runtime testable in Roblox Studio with a simple physical prototype. It does not add final art, chapter gameplay, monster AI, or production teleport place IDs.

## Goal

Create a real lobby-side portal zone that represents the future black Victorian carriage. The zone is invisible and server-authoritative. Visual carriage, fog, lamps, rain, and door models can be rough blockout props for now.

## Required Runtime

The server loads:

- `PortalService`
- `PortalZoneBinder`
- `Workspace/Portals`
- zone parts with a `PortalId` attribute

`PortalZoneBinder` safely no-ops if `Workspace/Portals` does not exist yet.

## Create Workspace/Portals

1. Open Roblox Studio.
2. Open the Rojo-synced London Below place.
3. In Explorer, right-click `Workspace`.
4. Insert `Folder`.
5. Name the folder exactly `Portals`.

## Create The Invisible Portal Zone

1. Right-click `Workspace/Portals`.
2. Insert `Part`.
3. Name the part exactly `main_carriage`.
4. Set `Anchored` to `true`.
5. Set `CanCollide` to `false`.
6. Set `CanTouch` to `true`.
7. Set `CanQuery` to `true`.
8. Set `Transparency` to `1`.
9. Set `Size` to a generous carriage boarding volume, for example `12, 8, 18`.
10. Move it where players should stand to board the carriage.
11. Add an Attribute:
    - Name: `PortalId`
    - Type: `String`
    - Value: `main_carriage`

The part name and `PortalId` should match. The attribute is the authority; the name is a readable fallback.

## Prototype Visual Carriage

This is not final art. Use simple parts only:

1. Create a rough black carriage blockout near the zone.
2. Add a simple doorway or boarding step.
3. Add a temporary lantern part near the door.
4. Add a fog-looking transparent part or Studio fog setting if desired.
5. Keep all visual parts outside `Workspace/Portals` unless they are trigger zones.

Only the invisible `main_carriage` trigger should be registered as a portal zone.

## Registration Flow

On server start:

1. `Bootstrap.server.lua` registers `PortalService`.
2. `Bootstrap.server.lua` registers `PortalZoneBinder`.
3. `PortalService` creates portal remotes and state.
4. `PortalZoneBinder.start()` searches for `Workspace/Portals`.
5. It scans descendant `BasePart` instances.
6. It reads each part's `PortalId` attribute.
7. It calls `PortalService.registerPortalZone(portalId, zonePart)`.

If `Workspace/Portals` is missing, invalid, or empty, the server logs warnings and continues.

## Local Studio Verification

1. Start Rojo:
   ```powershell
   rojo serve default.project.json
   ```
2. In Roblox Studio, connect Rojo.
3. Press Play.
4. Open the Developer Console.
5. Confirm there are no fatal bootstrap errors.
6. Confirm `PortalZoneBinder` logs that `main_carriage` was bound.
7. Walk the player into the invisible zone.
8. Watch `PortalClient` debug output for `PortalStateUpdated_v1`.

## Important Rules

- Do not put final art under `Workspace/Portals`.
- Do not let LocalScripts decide who is inside a portal.
- Do not rename the portal ID without also updating `SharedPortalConfig.Portals`.
- Do not call `TeleportService` from zone scripts.
- Do not create extra remotes for the portal.
- All launch paths must still go through `MatchmakingService.requestLaunch`.

## Future Fog Gate Setup

For a fog gate prototype:

1. Add another invisible part under `Workspace/Portals`.
2. Name it `fog_gate`.
3. Set `PortalId` to `fog_gate`.
4. Enable the matching portal config only when it is ready for testing.

## Future Chapter Door Setup

For a chapter door prototype:

1. Add another invisible part under `Workspace/Portals`.
2. Name it `chapter_door`.
3. Set `PortalId` to `chapter_door`.
4. Enable the matching portal config only when it is ready for testing.

## Known Prototype Limitations

- `Touched` and `TouchEnded` can be noisy in Roblox. The current binder is a foundation for Studio testing.
- Final production should use a stronger zone volume system that calls `PortalService.playerEnteredZone` and `PortalService.playerExitedZone`.
- Teleport will fail safely until real chapter place IDs are configured.
