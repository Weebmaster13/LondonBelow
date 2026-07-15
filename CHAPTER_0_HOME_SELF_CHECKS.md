# Chapter 0 Home Self-Checks

`Chapter0HomeSelfChecks.run()` verifies:

- canonical Chapter 0 definition validation;
- duplicate interaction rejection;
- duplicate room rejection;
- sparse room-array rejection;
- dictionary interaction-array rejection;
- unknown room-reference rejection;
- unknown room-connection rejection;
- room limit rejection;
- unsafe metadata rejection;
- optional completion-reference rejection;
- completion requires all required interactions;
- optional interactions cannot complete the chapter;
- player removal clears only the departing player's progress;
- player progress limit enforcement;
- reset clears per-player progress;
- snapshot isolation;
- service validation;
- no new remotes;
- no DataStore writes;
- no analytics or telemetry;
- Workspace mutation remains scoped to the owned Chapter 0 folder.

Self-checks are destructive and must run before the runtime is started.
