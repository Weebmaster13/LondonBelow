# Save / Journal / Identity Runtime Foundation

Phase 18 creates the server-authoritative foundation for reusable save profiles, checkpoints, journal unlocks, memory fragments, identity percentage, and replay meaning schemas.

This is not Chapter 0 content, Chapter 1 content, final UI, final story writing, cutscenes, or production DataStore persistence.

## Owns

- Profile foundation records.
- Checkpoint schemas.
- Journal entry unlock truth.
- Memory Fragment unlock truth.
- Identity percentage truth bounded from 0 to 100.
- Replay meaning schemas for future interpretation.
- Validation, serialization, diagnostics, snapshots, and deterministic self-checks.

## Does Not Own

- Client-owned progress.
- Final Journal UI.
- Final memories or final story dialogue.
- Narrative canon writing.
- Horror pacing.
- Monster AI.
- Workspace mutation.
- Remotes.
- DataStore production persistence.

## Runtime Location

The implementation lives under `src/ServerScriptService/Saving/Core` and is registered with Framework as `SaveCoordinator`.

## Future Use

Future UI may present approved server state. Future DataStore work may persist validated snapshots. Future Chapter content may define real journal and memory schemas. None of those are implemented in Phase 18.