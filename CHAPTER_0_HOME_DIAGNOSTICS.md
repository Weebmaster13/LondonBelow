# Chapter 0 Home Diagnostics

`Chapter0HomeCoordinator.inspect()` is registered under diagnostics provider `chapter0Home`.

Diagnostics expose:

- lifecycle state;
- `chapterId`;
- room, interaction, event, and validation-failure counts;
- current runtime status;
- last self-check result;
- lowerCamelCase `chapter0HomePosture`.

The posture confirms server authority, existing interaction runtime usage, no new remotes, no DataStore writes, no analytics, scoped Workspace mutation, and deterministic reset.

Snapshots are registered under provider `chapter0Home` and return isolated data copies through `Chapter0HomeSnapshots`.
