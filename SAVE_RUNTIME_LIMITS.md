# Save Runtime Limits

Phase 18 runtime state is bounded by explicit limits.

## Limits

- Profiles: `MaxProfiles`.
- Checkpoints per profile: `MaxCheckpointsPerProfile`.
- Journal entries per profile: `MaxJournalEntriesPerProfile`.
- Memory Fragments per profile: `MaxMemoryFragmentsPerProfile`.
- Replay states per profile: `MaxReplayStatesPerProfile`.
- Validation failures: `MaxValidationFailures`.
- Snapshot history: `MaxSnapshotHistory`.
- Payload depth: `MaxPayloadDepth`.
- Payload nodes: `MaxPayloadNodes`.
- Payload string length: `MaxPayloadStringLength`.

## Cleanup

`SaveCoordinator.shutdown` clears profiles, checkpoints, journal entries, memory fragments, identity percentages, replay state, and validation failures.

## Persistence Boundary

These limits govern in-memory foundation state only. Future DataStore persistence must add schema versions, migrations, write throttling, retry policy, and privacy review.