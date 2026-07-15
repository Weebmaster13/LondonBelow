# Chapter 0 Home Self-Checks

`Chapter0HomeSelfChecks.run()` verifies:

- canonical Chapter 0 definition validation;
- duplicate interaction rejection;
- unknown room-reference rejection;
- unsafe metadata rejection;
- completion requires all required interactions;
- reset clears per-player progress;
- snapshot isolation;
- service validation;
- no new remotes;
- no DataStore writes;
- no analytics or telemetry;
- Workspace mutation remains scoped to the owned Chapter 0 folder.

Self-checks are destructive and must run before the runtime is started.
