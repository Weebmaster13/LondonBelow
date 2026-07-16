# Chapter 0 Home Runtime

Phase 109 adds the minimum playable Chapter 0 Home vertical slice. Phase 110 hardens
that same runtime without adding Chapter 1, final art, final audio, save
persistence, or new networking. Phase 111 adds the first bounded atmospheric
feedback foundation inside the same runtime.

The runtime is owned by `Chapter0HomeCoordinator` at `src/ServerScriptService/Chapter0Home/Core`. It creates a bounded `Workspace.Chapter0Home` environment at startup, including a start spawn, a sitting room, hall, bedroom-door area, and four server-tagged interactables.

The playable loop is:

1. Spawn at `Chapter0HomeStart`.
2. Read Mum's note.
3. Turn the gas lamp.
4. Pick up Marmalade's ribbon.
5. Optionally open the bedroom door.

Completion requires the first three interactions. Progress is tracked per player on the server.

Phase 111 adds deterministic atmospheric feedback plans for the same four
interactions:

- Mum's note produces the `chapter0_home_note_read` prompt feedback plan.
- The gas lamp produces the `chapter0_home_gas_lamp_breath` visual feedback plan.
- Marmalade's ribbon produces the `chapter0_home_ribbon_found` prompt feedback plan.
- The optional bedroom door produces the `chapter0_home_bedroom_door_resists`
  screen-effect feedback plan without completing the chapter.

The plans are metadata only and are sent through the existing Player Experience
`Feedback_v1` RemoteEvent configured by `FeedbackService`. Phase 111 does not add
new remotes or a second presentation framework.

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
- Does not implement monster encounters, Chapter 1, final art, final audio, cutscenes, or save persistence.

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

## Phase 111 Atmospheric Feedback

Phase 111 extends the Chapter 0 Home definition with canonical
`atmosphericFeedback` entries. Each entry has a stable feedback id, interaction
reference, supported Player Experience feedback kind, instruction id, bounded
intensity, optional bounded duration, deterministic order, and lowerCamelCase
metadata.

Feedback history is tracked per player in Chapter0Home state and is bounded by
`Types.Limits.MaxFeedbackHistoryPerPlayer`. Reset and shutdown clear the history
with the rest of the owned Chapter 0 Home state. Player removal clears only the
departing player's feedback history.

## Runtime Certification

Phase 110 runtime certification is owned by
`ServerScriptService.Chapter0Home.Studio.Phase110CertificationRunner`. The runner is
Studio-only, requires explicit Workspace attribute `LondonPhase110RunSelfChecks =
true`, uses the shared Chapter0Home Studio self-check runner, verifies required
upstream PlayerExperience, Interaction Runtime, and Observation Engine regressions,
and restores temporary Chapter0Home runtime state after execution.
