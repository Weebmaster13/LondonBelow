# Puzzle Runtime Limits

Phase 24 limits:

- Puzzles: `320`
- Nodes: `1200`
- Nodes per puzzle: `120`
- Graphs: `320`
- Dependencies: `800`
- Dependencies per puzzle: `80`
- Conditions: `800`
- Conditions per puzzle: `80`
- Edges per puzzle: `240`
- Progress records: `500`
- Validation failures: `180`
- Snapshot history: `80`
- Payload depth: `8`
- Payload nodes: `280`
- Payload string length: `512`
- Tags: `24`

Bounded histories trim old records.

Shutdown clears puzzle schemas, progress records, validation failures, and snapshot history.
