# Chapter 0 Home Self-Checks

`Chapter0HomeSelfChecks.run()` verifies:

- canonical Chapter 0 definition validation;
- canonical atmospheric feedback definitions;
- exact atmospheric feedback count, ordering, ids, and interaction references;
- canonical environmental reaction definitions;
- exact environmental reaction count, ordering, ids, and interaction references;
- exact environmental reaction target references;
- exact environmental reaction attribute names and metadata attribute prefix;
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
- unsupported environmental reaction-field rejection;
- duplicate environmental reaction-id rejection;
- unknown environmental reaction interaction-reference rejection;
- invalid environmental reaction-kind rejection;
- invalid environmental reaction target-kind rejection;
- invalid environmental reaction root-target rejection;
- unknown environmental reaction room-target rejection;
- unknown environmental reaction interaction-target rejection;
- environmental reaction metadata-limit rejection;
- environmental reaction definition-limit rejection;
- invalid environmental reaction ordering rejection;
- invalid environmental reaction intensity rejection;
- sparse and dictionary-shaped environmental reaction-array rejection;
- unsafe environmental reaction metadata rejection;
- non-lowerCamelCase environmental reaction metadata rejection;
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
- optional interaction reaction does not complete the chapter;
- repeated interactions do not corrupt completion state;
- player removal clears only the departing player's progress;
- player removal clears only the departing player's feedback history;
- player removal clears only the departing player's reaction history;
- player progress limit enforcement;
- bounded feedback history and eviction behavior;
- bounded reaction history and eviction behavior;
- isolated feedback-history copies;
- isolated reaction-history copies;
- bounded event history;
- bounded validation-failure history;
- reset clears per-player progress;
- failed feedback validation does not mutate state;
- failed reaction validation does not mutate state;
- snapshot isolation;
- diagnostics isolation;
- lowerCamelCase atmospheric feedback diagnostics posture;
- lowerCamelCase environmental reaction diagnostics posture;
- atmospheric feedback definitions in isolated snapshots;
- environmental reaction definitions in isolated snapshots;
- environmental reaction attribute schema in isolated snapshots;
- service snapshot isolation;
- reset and shutdown bounded idempotence;
- service validation;
- no new remotes;
- no DataStore writes;
- no analytics or telemetry;
- no asset execution;
- no Monster AI;
- no combat, inventory, or save execution;
- no Chapter 1 content;
- Phase 109 regression protection;
- Phase 110 regression protection;
- Phase 111 regression protection;
- Phase 112 regression protection;
- Workspace mutation remains scoped to the owned Chapter 0 folder.

Self-checks are destructive and must run before the runtime is started. Static
inspection can confirm that the checks exist, but certification still requires the
Roblox Studio-gated runner to execute them and report final `PASS` with zero failures.

The Phase 110 Studio certification runner also verifies PlayerExperience remote
existence, RemoteEvent class identity, duplicate prevention, RemoteManager adoption
of Rojo-declared remotes, RemoteManager idempotent lookup, upstream PlayerExperience
self-checks, Interaction Runtime self-checks, and Observation Engine self-checks.
Its output separates setup failures from assertion failures.
