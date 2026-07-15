# Chapter 0 Home Runtime

Phase 109 adds the minimum playable Chapter 0 Home vertical slice.

The runtime is owned by `Chapter0HomeCoordinator` at `src/ServerScriptService/Chapter0Home/Core`. It creates a bounded `Workspace.Chapter0Home` environment at startup, including a start spawn, a sitting room, hall, bedroom-door area, and four server-tagged interactables.

The playable loop is:

1. Spawn at `Chapter0HomeStart`.
2. Read Mum's note.
3. Turn the gas lamp.
4. Pick up Marmalade's ribbon.
5. Optionally open the bedroom door.

Completion requires the first three interactions. Progress is tracked per player on the server.

## Boundaries

- Uses the existing `PlayerExperienceService` and `LondonInteractable` tag.
- Adds no new remotes.
- Adds no DataStore writes.
- Adds no analytics or telemetry.
- Mutates only the owned `Workspace.Chapter0Home` folder.
- Does not implement Phase 110, monster encounters, final art, final audio, cutscenes, or save persistence.

## Reset

`Chapter0HomeCoordinator.reset()` destroys and recreates only `Workspace.Chapter0Home`, clears per-player progress, and rebuilds the authored room/interactable graph deterministically.
