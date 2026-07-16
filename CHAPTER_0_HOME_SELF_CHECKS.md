# Chapter 0 Home Self-Checks

`Chapter0HomeSelfChecks.run()` verifies:

- canonical Chapter 0 definition validation;
- canonical atmospheric feedback definitions;
- exact atmospheric feedback count, ordering, ids, and interaction references;
- canonical environmental reaction definitions;
- exact environmental reaction count, ordering, ids, and interaction references;
- exact environmental reaction target references;
- exact environmental reaction attribute names and metadata attribute prefix;
- canonical atmospheric progression definitions;
- exact atmospheric progression stage count, ids, and ordering;
- exact atmospheric progression transition count, ids, and ordering;
- exact atmospheric progression interaction, feedback, and reaction references;
- optional bedroom-door progression modifier behavior;
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
- unsupported progression stage and transition field rejection;
- duplicate progression stage and transition id rejection;
- missing and multiple initial progression stage rejection;
- unknown progression stage, interaction, feedback, and reaction references;
- invalid progression ordering and cyclic progression rejection;
- unreachable progression and impossible-requirement rejection;
- optional progression completion-gate rejection;
- invalid progression intensity and completion relevance rejection;
- progression metadata-limit, stage-limit, and transition-limit rejection;
- sparse and dictionary-shaped progression-array rejection;
- unsafe progression metadata rejection;
- non-lowerCamelCase progression metadata rejection;
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
- bounded progression history and eviction behavior;
- bounded optional progression modifier history and eviction behavior;
- isolated feedback-history copies;
- isolated reaction-history copies;
- isolated progression-history copies;
- bounded event history;
- bounded validation-failure history;
- reset clears per-player progress;
- failed feedback validation does not mutate state;
- failed reaction validation does not mutate state;
- failed progression validation does not mutate state;
- snapshot isolation;
- diagnostics isolation;
- lowerCamelCase atmospheric feedback diagnostics posture;
- lowerCamelCase environmental reaction diagnostics posture;
- lowerCamelCase atmospheric progression diagnostics posture;
- atmospheric feedback definitions in isolated snapshots;
- environmental reaction definitions in isolated snapshots;
- environmental reaction attribute schema in isolated snapshots;
- atmospheric progression definitions, limits, and posture in isolated snapshots;
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
- Phase 113 regression protection;
- Phase 114 regression protection;
- Workspace mutation remains scoped to the owned Chapter 0 folder.

Phase 115 expands static self-check definitions for exact atmospheric progression
hardening: canonical stage count, stage ids, stage ordering, initial stage,
transition count, transition ids, transition ordering, from-stage references,
to-stage references, interaction references, feedback references, environmental
reaction references, required-interaction sequences, optional-modifier identity,
completion relevance, intensity posture, drift rejection, duplicate-requirement
rejection, out-of-order transition no mutation, unknown transition no mutation,
idempotent repeated transitions, diagnostics posture, snapshot schema evidence, and
Phase 114 regression protection.

Self-checks are destructive and must run before the runtime is started. Static
inspection can confirm that the checks exist, but certification still requires the
Roblox Studio-gated runner to execute them and report final `PASS` with zero failures.

The Phase 110 Studio certification runner also verifies PlayerExperience remote
existence, RemoteEvent class identity, duplicate prevention, RemoteManager adoption
of Rojo-declared remotes, RemoteManager idempotent lookup, upstream PlayerExperience
self-checks, Interaction Runtime self-checks, and Observation Engine self-checks.
Its output separates setup failures from assertion failures.

## Phase 116 Observation Integration Self-Checks

Phase 116 expands static self-check definitions for canonical observation fact
count, exact fact ids, deterministic ordering, exact source chapter id, exact source
runtime id, exact contract version, exact authority marker, observation kinds,
interaction references, stage references, feedback references, environmental
reaction references, optional modifier semantics, completion relevance, duplicate
fact rejection, duplicate runtime id rejection, malformed definition rejection,
unsupported-field rejection, unknown-reference rejection, invalid source runtime
rejection, invalid authority rejection, invalid kind rejection, invalid ordering
rejection, invalid intensity rejection, metadata-limit rejection, definition-limit
rejection, sparse-array rejection, dictionary-array rejection, unsafe payload
rejection, failed-validation no mutation, deterministic deduplication, repeated
emission idempotence, per-player isolation, optional observation modifier behavior,
player-removal cleanup, reset cleanup, shutdown cleanup, diagnostics isolation,
snapshot isolation, lowerCamelCase observation posture, Observation Runtime
read-only posture, Chapter0Home authority posture, no new remotes, no hidden client
authority, no persistence, no analytics, no telemetry, no Monster AI, no combat, no
inventory, no save execution, no Chapter 1 content, and Phase 109 through Phase 115
regression protection.

## Phase 118 Certification Review Self-Checks

Phase 118 adds certification-review self-check definitions through the Studio-only
runner contract for exact phase identity, exact runner identity, exact schema
version, explicit gate posture, concurrent-run rejection, stable status values,
required suite ids, duplicate suite rejection, setup/assertion/cleanup/upstream
classification, runtime-unavailable classification, skipped-suite classification,
successful-result consistency, invalid-total rejection, passed-with-failure
rejection, certified-without-execution rejection, certified-outside-Studio
rejection, cleanup-after-failure posture, active-run marker cleanup, result
deep-copy isolation, failure evidence isolation, diagnostics isolation, snapshot
isolation, no new remotes, no persistence, no analytics, no telemetry, no gameplay
mutation, no Chapter 1 content, and Phase 109 through Phase 117 regression
protection.

## Phase 117 Observation Integration Hardening Self-Checks

Phase 117 expands static self-check definitions for centralized publication signal
identity, Chapter observation signal identity, optional observation modifier fact
identity, metadata schema keys, source-reference schema, snapshot schema names,
expanded lowerCamelCase posture keys, metadata schema drift rejection, missing
canonical fact rejection, unauthorized extra fact rejection, future-stage
publication rejection, optional observation current-stage gating, exact diagnostics
posture, exact snapshot source-reference schema, duplicate-publication prevention,
Observation Runtime read-only posture, Chapter0Home authority posture, and Phase 116
regression protection.
