# Save Validation

`SaveValidation` enforces server-owned safe schemas before data enters the runtime.

## Rejects

- Missing or invalid profile, checkpoint, journal, memory, and replay IDs.
- Duplicate records through runtime checks.
- Invalid identity deltas.
- Client-like payloads.
- Workspace, remote, UI, cutscene, final story, Monster AI, horror pacing, temporary pressure, Lighting, and Audio fields.
- Unsafe runtime values and cyclic payloads.

## Identity

Identity deltas must be numeric. `IdentityRuntime` clamps final identity percentage from 0 to 100.