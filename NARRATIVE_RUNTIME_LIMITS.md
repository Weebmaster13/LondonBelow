# Narrative Runtime Limits

Narrative Runtime uses hard limits so future chapters cannot accidentally turn schema data into unbounded live content.

## Runtime Limits

- Narrative beats: `160`
- Story gates: `160`
- Reveal eligibility records: `240`
- Emotional protections: `160`
- Validation failures: `160`
- Snapshot history: `80`
- Payload depth: `8`
- Payload nodes: `240`
- Payload string length: `512`
- Identity percentage: `0` to `100`
- Identity delta: `-100` to `100`

When a bounded history exceeds its limit, the oldest records are removed. These limits protect long-running servers from memory growth while keeping enough context for diagnostics.

## Unknown or Unsafe Data

Unknown narrative data is not trusted. Any schema containing runtime values, execution-like fields, final dialogue, Chapter content, UI, cutscenes, Workspace, Audio, Lighting, Monster AI, or horror pacing ownership is rejected before state changes.

## Future Chapter Use

Chapter systems may register schema ids, requirements, and eligibility records. They must not use Narrative Runtime to store final prose, run cutscenes, mutate Workspace, play audio, change Lighting, or decide horror pacing.
