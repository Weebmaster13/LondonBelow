# Chapter 0 Home Diagnostics

`Chapter0HomeCoordinator.inspect()` is registered under diagnostics provider `chapter0Home`.

Diagnostics expose:

- lifecycle state;
- `chapterId`;
- room, interaction, event, and validation-failure counts;
- owned root, foreign root, world connection, and lifecycle connection counts;
- current runtime status;
- last self-check result;
- lowerCamelCase `chapter0HomePosture`.

The posture confirms server authority, existing interaction runtime usage, no new
remotes, no DataStore writes, no analytics, scoped Workspace mutation, and
deterministic reset. Phase 110 diagnostics make duplicate-root and connection-cleanup
posture visible without exposing Instances, connections, callbacks, or mutable
internal state.

Snapshots are registered under provider `chapter0Home` and return isolated data copies through `Chapter0HomeSnapshots`.

Phase 110 runtime certification checks the diagnostics provider name, lowerCamelCase
`chapter0HomePosture`, owned-root counts, foreign-root counts, world-connection
counts, lifecycle-connection counts, and isolation from Roblox runtime objects.
