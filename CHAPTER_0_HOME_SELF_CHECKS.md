# Chapter 0 Home Self-Checks

`Chapter0HomeSelfChecks.run()` verifies:

- canonical Chapter 0 definition validation;
- duplicate interaction rejection;
- duplicate room rejection;
- sparse room-array rejection;
- dictionary interaction-array rejection;
- unknown room-reference rejection;
- unknown room-connection rejection;
- unsupported definition-field rejection;
- unsupported room-field rejection;
- unsupported interaction-field rejection;
- self-referential room-connection rejection;
- duplicate room-connection rejection;
- room limit rejection;
- bounded position validation;
- negative, zero, and oversized dimension rejection;
- unsafe metadata rejection;
- deeply unsafe metadata rejection;
- cyclic metadata rejection;
- missing completion-array rejection;
- duplicate completion-id rejection;
- required-completion omission rejection;
- optional completion-reference rejection;
- cycle-safe serialization;
- mutable-reference isolation in serialization;
- unsafe callback stripping during serialization;
- completion requires all required interactions;
- optional interactions cannot complete the chapter;
- repeated interactions do not corrupt completion state;
- player removal clears only the departing player's progress;
- player progress limit enforcement;
- bounded event history;
- bounded validation-failure history;
- reset clears per-player progress;
- snapshot isolation;
- diagnostics isolation;
- service snapshot isolation;
- reset and shutdown bounded idempotence;
- service validation;
- no new remotes;
- no DataStore writes;
- no analytics or telemetry;
- Workspace mutation remains scoped to the owned Chapter 0 folder.

Self-checks are destructive and must run before the runtime is started. Static
inspection can confirm that the checks exist, but certification still requires the
Roblox Studio-gated runner to execute them and report final `PASS` with zero failures.
