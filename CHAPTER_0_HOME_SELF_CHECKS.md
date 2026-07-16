# Chapter 0 Home Self-Checks

`Chapter0HomeSelfChecks.run()` verifies:

- canonical Chapter 0 definition validation;
- canonical atmospheric feedback definitions;
- exact atmospheric feedback count, ordering, ids, and interaction references;
- duplicate interaction rejection;
- duplicate room rejection;
- sparse room-array rejection;
- dictionary interaction-array rejection;
- unknown room-reference rejection;
- unknown room-connection rejection;
- unsupported definition-field rejection;
- unsupported room-field rejection;
- unsupported interaction-field rejection;
- unsupported feedback-field rejection;
- duplicate feedback-id rejection;
- unknown feedback interaction-reference rejection;
- invalid feedback-kind rejection;
- invalid feedback ordering rejection;
- invalid feedback intensity and duration rejection;
- oversized feedback payload rejection;
- sparse and dictionary-shaped feedback-array rejection;
- non-lowerCamelCase feedback metadata rejection;
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
- optional interaction feedback does not complete the chapter;
- repeated interactions do not corrupt completion state;
- player removal clears only the departing player's progress;
- player removal clears only the departing player's feedback history;
- player progress limit enforcement;
- bounded feedback history and eviction behavior;
- isolated feedback-history copies;
- bounded event history;
- bounded validation-failure history;
- reset clears per-player progress;
- failed feedback validation does not mutate state;
- snapshot isolation;
- diagnostics isolation;
- lowerCamelCase atmospheric feedback diagnostics posture;
- atmospheric feedback definitions in isolated snapshots;
- service snapshot isolation;
- reset and shutdown bounded idempotence;
- service validation;
- no new remotes;
- no DataStore writes;
- no analytics or telemetry;
- no asset execution;
- no Monster AI;
- no Chapter 1 content;
- Phase 109 regression protection;
- Phase 110 regression protection;
- Workspace mutation remains scoped to the owned Chapter 0 folder.

Self-checks are destructive and must run before the runtime is started. Static
inspection can confirm that the checks exist, but certification still requires the
Roblox Studio-gated runner to execute them and report final `PASS` with zero failures.

The Phase 110 Studio certification runner also verifies PlayerExperience remote
existence, RemoteEvent class identity, duplicate prevention, RemoteManager adoption
of Rojo-declared remotes, RemoteManager idempotent lookup, upstream PlayerExperience
self-checks, Interaction Runtime self-checks, and Observation Engine self-checks.
Its output separates setup failures from assertion failures.
