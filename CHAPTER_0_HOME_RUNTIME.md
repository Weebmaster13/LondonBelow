# Chapter 0 Home Runtime

Phase 109 adds the minimum playable Chapter 0 Home vertical slice. Phase 110 hardens
that same runtime without adding Chapter 1, Phase 111, final art, final audio, save
persistence, or new networking.

The runtime is owned by `Chapter0HomeCoordinator` at `src/ServerScriptService/Chapter0Home/Core`. It creates a bounded `Workspace.Chapter0Home` environment at startup, including a start spawn, a sitting room, hall, bedroom-door area, and four server-tagged interactables.

The playable loop is:

1. Spawn at `Chapter0HomeStart`.
2. Read Mum's note.
3. Turn the gas lamp.
4. Pick up Marmalade's ribbon.
5. Optionally open the bedroom door.

Completion requires the first three interactions. Progress is tracked per player on the server.

Runtime hardening verifies that optional interactions do not complete the chapter,
player removal clears only the departing player's progress, repeated interactions do
not corrupt completion state, per-player progress remains bounded, and malformed or
sparse content definitions cannot create Workspace content.

## Boundaries

- Uses the existing `PlayerExperienceService` and `LondonInteractable` tag.
- Adds no new remotes.
- Adds no DataStore writes.
- Adds no analytics or telemetry.
- Mutates only the owned `Workspace.Chapter0Home` folder.
- Does not implement Phase 111, monster encounters, final art, final audio, cutscenes, or save persistence.

## Reset

`Chapter0HomeCoordinator.reset()` destroys and recreates only owned
`Workspace.Chapter0Home` roots marked with the runtime owner attributes, refuses to
overwrite unowned folders with the same name, clears per-player progress, and rebuilds
the authored room/interactable graph deterministically.

## Phase 110 Hardening

Phase 110 adds explicit protection for duplicate tags, duplicate room connections,
unsupported schema fields, unsafe Vector3 coordinates and dimensions, cycle-safe
serialization, bounded validation-failure history, owned-root diagnostics, and
idempotent reset/shutdown cleanup. The runtime still uses the existing
PlayerExperience remote contract and does not create a second Chapter 0 gameplay
system.
