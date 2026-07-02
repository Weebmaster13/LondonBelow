# World Runtime Foundation

Phase 26 creates the server-authoritative schema truth for London Below's world structure. It describes districts, regions, buildings, floors, rooms, zones, traversal links, streaming schemas, environmental classifications, world tags, and world metadata.

It does not build the world. It does not mutate Workspace, generate terrain, generate maps, stream rooms, load rooms, teleport players, move players, open doors, execute interactions, solve puzzles, execute inventory, create remotes, trust clients, or add Chapter content.

Future systems may reference World Runtime schema ids. They must not treat this runtime as a construction, streaming, traversal, pathfinding, or gameplay execution service.

## Modules

- `WorldCoordinator`: lifecycle and public registration API.
- `WorldDistrictRuntime`: central bounded schema store.
- `WorldRegionRuntime`, `WorldBuildingRuntime`, `WorldFloorRuntime`, `WorldRoomRuntime`, `WorldZoneRuntime`: focused registration facades.
- `WorldConnectionRuntime`: traversal connection schemas only.
- `WorldStreamingRuntime`: streaming region schemas only.
- `WorldClassificationRuntime`: environmental classification schemas.
- `WorldTagRuntime`: world tag schemas.
- `WorldValidation`: server-side validation boundary.
- `WorldSerialization`: deep-copy and sanitization boundary.
- `WorldDiagnostics`, `WorldSnapshots`, `WorldSelfChecks`: observability and proof.
