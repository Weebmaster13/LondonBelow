# Save Self-Checks

Phase 18 self-checks certify the Save / Journal / Identity foundation without creating UI, story content, remotes, Workspace mutation, or DataStore writes.

## Proved Conditions

- Malformed profile rejects.
- Duplicate profile rejects.
- Valid profile creates.
- Valid checkpoint creates.
- Invalid checkpoint rejects.
- Unsafe checkpoint payload rejects.
- Valid Journal entry unlocks.
- Duplicate Journal entry rejects.
- Unsafe Journal payload rejects.
- Valid Memory Fragment unlocks.
- Duplicate Memory Fragment rejects.
- Unsafe Memory payload rejects.
- Identity increase clamps to 100.
- Identity decrease clamps to 0.
- Invalid identity delta rejects.
- Replay state creates.
- Invalid replay state rejects.
- Serialization rejects cycles.
- Serialization rejects unsafe runtime values.
- Snapshots are isolated deep copies.
- Diagnostics are read-only.
- Runtime state remains bounded.
- Shutdown clears state.
- No Workspace mutation, remotes, final UI, Chapter content, Monster AI, or horror pacing ownership exists.

## Safety Boundary

Self-checks are destructive and may only run before the service starts. They use placeholder schema IDs only and do not author final story.