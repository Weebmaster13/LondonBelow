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

## Phase 119 Certification Hardening Self-Checks

Phase 119 adds static certification-contract self-check definitions for exact
runner id, phase identity, phase name, schema version, runtime name, gate
attribute, active-marker attribute, required suite count, suite ids, suite
ordering, status values, result fields, failure fields, next-action values,
diagnostic posture keys, snapshot schema names, certification requirements,
successful-result validation, unauthorized-field rejection, skipped-required-suite
rejection, certified-with-failure rejection, runtime-object contamination
rejection, result isolation, failure isolation, diagnostics isolation, snapshot
isolation, no new remotes, no persistence, no analytics, no telemetry, no gameplay
changes, no Chapter 1 content, and Phase 109 through Phase 118 regression
protection.

## Phase 120 Evidence Capture Self-Checks

Phase 120 adds evidence-review coverage through the committed evidence artifact and
local wrapper recognition for exact evidence artifact identity, source commit
attribution, local and remote source alignment, working-tree cleanliness at capture,
authoritative-versus-wrapper distinction, runtime-unavailable and execution-blocked
classification, certification decision false without Studio evidence, skipped
suite and not-executed totals truthfulness, no stale evidence reuse, evidence
serialization safety, no secrets, no runtime objects, exact certification scope, no
over-certification, no new remotes, no persistence, no analytics, no telemetry, no
gameplay changes, no Chapter 1 content, and Phase 109 through Phase 119 regression
protection.

## Phase 121 Studio Evidence Capture Self-Checks

Phase 121 adds wrapper self-check coverage for Studio capture command behavior:
JSON schema, Markdown schema, source attribution, evidence validation, decision
consistency, machine-readable export, artifact overwrite safety, stale artifact
rejection, corrupted artifact rejection, wrapper exit codes, wrapper argument
validation, cleanup verification, rerun safety, runtime truthfulness, no alternate
certification decision function, no gameplay changes, no new remotes, no
persistence, no analytics, no telemetry, and no Chapter 1 content.

## Phase 122 Studio Automation Bridge Self-Checks

Phase 122 adds bridge self-check coverage for Studio discovery, Studio version
detection, execution bridge availability, launch argument validation, runner
invocation guardrails, result transport posture, bridge retry safety, duplicate
execution prevention, timeout handling, cancellation handling, unexpected Studio
termination classification, bridge logging, evidence forwarding, wrapper
consistency, source attribution preservation, and no certification logic
duplication.

## Phase 123 Structured Capture Self-Checks

Phase 123 expands bridge self-check coverage for structured capture detection,
capture availability, capture transport, capture schema, bridge forwarding, invalid
capture rejection, partial capture rejection, corrupt capture rejection, timeout
classification, unsupported API detection, source attribution preservation, wrapper
consistency, stable exit codes, and rerun safety.

## Phase 124 MCP Activation Self-Checks

Phase 124 expands bridge coverage for MCP activation detection, repository opt-in,
activation refusal, activation success-path shape, capture forwarding, bridge
integration, transport integrity, runner identity, capture identity, duplicate
activation prevention, timeout handling, disconnect handling, bridge recovery,
wrapper consistency, and stable exit codes.

## Phase 125 MCP Runner Binding Self-Checks

Phase 125 expands bridge coverage for documented MCP command detection, runner
command discovery, binding validation, unsupported binding refusal, duplicate
binding prevention, bridge forwarding, wrapper consistency, stable exit codes,
disconnect handling, and missing session handling.

## Phase 126 Connected Studio MCP Session Self-Checks

Phase 126 adds session authority coverage for repository validation, bridge
ownership, session discovery, immutable identity validation, state-machine
transitions, health transitions, heartbeat evidence, timeout and reconnect
classification, disconnect classification, duplicate-session prevention, stale and
expired session rejection, unsupported protocol rejection, identity mismatch
rejection, permission denial, evidence forwarding, wrapper consistency,
deterministic exit codes, deterministic timestamps, rerun safety, crash and
interruption recovery posture, source attribution preservation, certification
ownership preservation, no duplicated certification logic, no gameplay mutation, no
runtime mutation, no networking creation, no remotes, no persistence, no analytics,
and no telemetry.

## Phase 127 Studio MCP Runner Authority Self-Checks

Phase 127 adds Runner Authority coverage for runner identity validation, request
identity validation, request creation, request expiration, queued transition,
waiting transition, blocked transition, timeout ownership, retry ownership,
cancellation ownership, duplicate request prevention, duplicate execution
prevention, stale request rejection, invalid request rejection, missing session
handling, invalid binding handling, activation failure handling, deterministic
timestamps, deterministic exit codes, bridge forwarding, evidence forwarding,
wrapper consistency, interruption recovery, rerun safety, crash recovery, authority
ownership preservation, certification ownership preservation, source attribution
preservation, no runtime mutation, no gameplay mutation, no networking, no
persistence, no analytics, no telemetry, session authority consumption, closed
state machine, closed status values, and exact request fields.

## Phase 128 Runner Authority Hardening Self-Checks

Phase 128 expands Runner Authority coverage for contract version validation, schema
compatibility, immutable request identity, immutable audit entries, legal
transition validation, illegal transition rejection, skipped transition rejection,
cyclic transition rejection, duplicate completion rejection, duplicate cancellation
rejection, duplicate timeout rejection, terminal state immutability, diagnostics
schema validation, deterministic serialization, diagnostics field closure, audit
validation, transition validation, backward compatibility validation, and
certification ownership leakage absence.
## Phase 129 Studio MCP Integration Contract Self-Checks

`npm run london:studio:mcp:integration:phase120:selfcheck` verifies the Phase 129
integration contract. It covers protocol version validation, contract version
validation, compatibility, handshake state machine closure, capabilities, request,
response, event, and structured-result schemas, deterministic serialization,
authority ownership, protocol/schema drift detection, source attribution,
deterministic exit codes, rerun stability, backward compatibility, and boundary
preservation.

## Phase 130 Studio MCP Capability Negotiation Self-Checks

`npm run london:studio:capabilities:phase130:selfcheck` verifies capability
advertisement validation, required and optional capability behavior, dependency
and conflict rejection, immutable negotiated profiles, lifecycle closure,
deterministic serialization, audit validation, source attribution, authority
isolation, and certification-boundary preservation.

## Phase 131 Studio MCP Execution Readiness Self-Checks

`npm run london:studio:readiness:phase131:selfcheck` verifies readiness lifecycle
closure, prerequisite aggregation, single decision publication, immutable
readiness profiles, blocking reason validation, authority aggregation, audit
validation, deterministic serialization, source attribution, no execution, and
certification-boundary preservation.

## Phase 132 Studio MCP Execution Planning Self-Checks

`npm run london:studio:planning:phase132:selfcheck` verifies planning lifecycle
closure, execution graph validation, dependency validation, stage ordering,
checkpoint validation, immutable execution plans, immutable execution graphs,
immutable checkpoints, deterministic serialization, deterministic timestamps,
deterministic exit codes, audit validation, rerun stability, authority isolation,
readiness consumption, no execution, no runtime evidence, no gameplay mutation,
no networking, no persistence, no analytics, no telemetry, and certification
ownership leakage absence.

## Phase 133 Studio MCP Execution Orchestrator Self-Checks

`npm run london:studio:orchestrator:phase133:selfcheck` verifies orchestration
lifecycle closure, orchestration graph validation, dependency validation, stage
ordering, execution context validation, retry policy validation, cancellation
policy validation, immutable orchestration, immutable execution context,
deterministic serialization, deterministic timestamps, deterministic exit codes,
audit validation, rerun stability, authority isolation, planning consumption, no
execution, no runtime evidence, no gameplay mutation, no networking, no
persistence, no analytics, no telemetry, and certification ownership leakage
absence.

## Phase 134 Studio MCP Execution Request Authority Self-Checks

`npm run london:studio:request:phase134:selfcheck` verifies request lifecycle
closure, exact request schema validation, identifier validation, duplicate
identifier rejection, execution intent validation, orchestration compatibility,
readiness compatibility, capability compatibility, immutable request publication,
deterministic serialization, deterministic timestamps, deterministic exit codes,
diagnostics validation, audit validation, rerun stability, authority isolation,
orchestration consumption, no execution, no runtime evidence, no gameplay
mutation, no networking, no persistence, no analytics, no telemetry, and
certification ownership leakage absence.

## Phase 135 Studio MCP Execution Dispatch Authority Self-Checks

`npm run london:studio:dispatch:phase135:selfcheck` verifies dispatch lifecycle
closure, illegal transition rejection, skipped transition rejection, terminal
mutation rejection, exact dispatch schema validation, unknown and missing field
rejection, duplicate identifier rejection, dispatch eligibility validation,
blocked-state truthfulness, execution intent consumption, request compatibility,
orchestration compatibility, planning compatibility, readiness compatibility,
capability compatibility, protocol compatibility, immutable dispatch publication,
diagnostics validation, immutable audit validation, duplicate audit rejection,
deterministic serialization, deterministic timestamps, deterministic exit codes,
rerun stability, authority isolation, upstream regression compatibility, no Studio
execution, no runner invocation, no transport, no runtime evidence, no gameplay
mutation, no networking, no persistence, no analytics, no telemetry, and
certification ownership leakage absence.

## Phase 136 Studio MCP External Execution Boundary Self-Checks

`npm run london:studio:boundary:phase136:selfcheck` verifies boundary lifecycle
closure, missing-dispatch rejection, ineligible and rejected boundary paths,
construction and freeze failure posture, illegal/skipped/cyclic/terminal mutation
rejection, exact handoff schema, unknown/missing field rejection, duplicate
identity rejection, dispatch/request/orchestration/plan/readiness correlation,
protocol and capability compatibility, dispatch eligibility preservation,
blocked boundary truthfulness, ownership-state validation, external-consumer
contract schema and consumer type validation, immutable handoff and contract
publication, diagnostics validation, immutable audit validation, duplicate and
ordered audit rejection, deterministic identifiers, timestamps, serialization,
exit codes, rerun stability, authority isolation, upstream regression
compatibility, no Studio execution, no runner invocation, no child-process
execution, no network transport, no MCP communication, no external consumer
discovery, no runtime evidence, no structured result capture, no gameplay
mutation, no persistence, no analytics, no telemetry, and certification ownership
leakage absence.
