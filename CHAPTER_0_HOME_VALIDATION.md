# Chapter 0 Home Validation

Phase 109 validation is performed by `Chapter0HomeValidation`. Phase 110 expands the
same validator with closed schema checks, bounded Vector3 checks, and deeper unsafe
payload rejection.

Validation rejects:

- non-table definitions;
- invalid `chapterId`;
- missing display name or spawn;
- unsupported definition, room, or interaction fields;
- duplicate room ids;
- duplicate interaction ids;
- sparse or dictionary-shaped room, interaction, connection, and completion arrays;
- unknown room references;
- unknown room-connection references;
- self-referential room connections;
- duplicate room connections;
- unsupported room or interaction kinds;
- missing prompts;
- over-limit room or interaction counts;
- unbounded, NaN-like, or infinite positions;
- zero, negative, oversized, NaN-like, or infinite room and interaction dimensions;
- unsafe metadata keys related to DataStore, HTTP, MessagingService, telemetry, analytics, remotes, or client authority;
- unsafe metadata payloads containing callbacks, Roblox runtime objects, cycles, or excessive nesting;
- completion requirements that reference missing interactions.
- completion requirements that reference optional interactions;
- required interactions missing from the completion list.
- malformed atmospheric feedback definitions;
- unsupported atmospheric feedback fields;
- duplicate feedback ids;
- unknown feedback interaction references;
- invalid feedback kinds;
- invalid feedback ordering;
- oversized feedback instruction ids;
- invalid feedback intensity or duration;
- sparse or dictionary-shaped atmospheric feedback arrays;
- non-lowerCamelCase feedback metadata keys;
- unsafe feedback metadata, runtime objects, remotes, callbacks, connections, and client-authority markers.
- malformed environmental reaction definitions;
- unsupported environmental reaction fields;
- duplicate reaction ids;
- unknown reaction interaction references;
- unknown reaction room or interaction targets;
- invalid reaction kinds or target kinds;
- invalid Chapter root reaction targets;
- invalid reaction ordering;
- invalid reaction intensity;
- over-limit environmental reaction definitions;
- over-limit environmental reaction metadata keys;
- sparse or dictionary-shaped environmental reaction arrays;
- non-lowerCamelCase environmental reaction metadata keys;
- unsafe environmental reaction metadata, runtime objects, remotes, callbacks, connections, and client-authority markers.
- malformed atmospheric progression stage or transition definitions;
- unsupported atmospheric progression fields;
- duplicate progression stage ids;
- duplicate progression transition ids;
- missing or multiple initial progression stages;
- unknown progression stage references;
- unknown progression interaction references;
- unknown progression feedback references;
- unknown progression environmental reaction references;
- invalid progression ordering;
- cyclic or unreachable progression;
- impossible transition requirements;
- optional interactions marked as mandatory progression gates;
- invalid progression intensity or completion relevance;
- over-limit progression stages, transitions, metadata keys, optional modifiers, history, or transition requirements;
- sparse or dictionary-shaped progression arrays;
- non-lowerCamelCase progression metadata keys;
- unsafe progression metadata, runtime objects, remotes, callbacks, connections, and client-authority markers.

Validation runs before `Chapter0HomeCoordinator` creates Workspace content.
Phase 111 feedback validation runs before any atmospheric feedback state mutation
or Player Experience feedback dispatch.
Phase 112 reaction validation runs before any environmental reaction state mutation
or owned Workspace attribute update.
Phase 113 hardening verifies these reaction rules remain exact, deterministic, and
bounded while keeping reaction attributes scoped to the owned Chapter 0 Home root.
Phase 114 progression validation runs before any atmospheric progression state
mutation and requires every transition to reference existing interactions, feedback,
and environmental reactions.

Phase 115 hardening additionally rejects exact progression-contract drift before
mutation. Validation compares definitions against the centralized
`Chapter0HomeTypes` contract for exact stage count, transition count, stage ids,
transition ids, initial stage id, stage ordering, transition ordering, from-stage
references, to-stage references, interaction references, feedback references,
environmental reaction references, required-interaction sequence ordering,
optional-modifier semantics, completion relevance, intensity values, and metadata.
Duplicate requirements, requirement-order drift, optional modifiers that advance a
stage, optional modifiers that become completion relevant, and optional
interactions promoted into mandatory progression gates are invalid.

Phase 110 runtime certification verifies these validation guarantees through the
Studio-gated self-check suite. Static validation alone is not certification evidence.

## Phase 116 Observation Validation

Phase 116 validates the canonical observation fact contract before startup,
mutation, or publication. Validation rejects unsupported fields, duplicate fact ids,
duplicate observation ids, unknown interaction references, unknown progression
stage references, unknown feedback references, unknown environmental reaction
references, invalid source runtime identity, invalid server authority marker,
invalid observation kind, invalid deterministic ordering, invalid intensity,
invalid completion relevance, invalid optional modifier marker, missing or
unsupported contract version, excessive metadata, excessive definitions, sparse
arrays, dictionary-shaped arrays, non-lowerCamelCase metadata, unsafe metadata,
callbacks, Roblox runtime objects, remotes, connections, cyclic tables, and exact
contract drift.

State-level observation recording also rejects unknown facts, malformed payloads,
payloads that do not exactly match canonical definitions, facts whose source
interaction has not been accepted, and facts whose source progression stage is not
current.

## Phase 117 Observation Validation Hardening

Phase 117 additionally treats the observation metadata schema, source-reference
schema, publication signal identity, optional modifier fact identity, snapshot schema
names, and expanded posture keys as centralized review surfaces. Validation rejects
metadata schema drift, missing canonical facts, unauthorized extra facts, fact id
drift, ordering drift, source chapter drift, source runtime drift, contract version
drift, authority drift, kind drift, reference drift, completion relevance drift,
optional marker drift, intensity drift, unsupported fields, sparse arrays,
dictionary-shaped arrays, unsafe payloads, cyclic payloads, and serialization
contamination before mutation or publication.

## Phase 118 Certification Result Validation

Phase 118 validates certification evidence before returning it. Validation rejects
unsupported result fields, non-lowerCamelCase fields, invalid schema version,
invalid phase identity, invalid runner identity, invalid statuses, duplicate suite
ids, unknown executed or skipped suites, negative totals, inconsistent totals,
passed status with failures or skipped required suites, passed status outside Studio,
passed status without cleanup success, passed status without upstream success,
runtime-unavailable certification, malformed failure evidence, runtime objects,
Instances, remotes, connections, callbacks, functions, cyclic tables, and mutable
shared result tables.

## Phase 119 Certification Validation Hardening

Phase 119 treats certification validation as a frozen contract. Validation now
rejects missing required fields, unauthorized extra fields, incorrect field casing,
incorrect runtime identity, incorrect gate or active-run posture, invalid setup,
assertion, cleanup, or upstream statuses, duplicate or unknown required suites,
required-suite classification gaps, suite-order drift, fractional or negative
totals, mixed executed/not-executed totals, failure-list inconsistencies, passed
states with skipped suites or failures, runtime-unavailable states with executed
totals, malformed evidence ids, malformed source commit posture, invalid next
actions, oversized values, cyclic tables, functions, threads, userdata, Instances,
connections, remotes, and any production-certification decision drift.

## Phase 120 Evidence Validation

Phase 120 validates the evidence-capture state rather than runtime behavior. No
authoritative Studio structured result exists, so `Phase118CertificationContract`
cannot validate a passing result and `canProductionCertify` remains false.

The Phase 120 evidence artifact verifies the intended source commit, remote
alignment, working-tree cleanliness at capture, expected runner identity, expected
gate identity, required suite identities, local-wrapper distinction, no stale
evidence reuse, no secrets, no runtime objects, and exact Production Candidate
classification.
## Phase 121 Studio Evidence Capture Validation

Phase 121 validation is limited to tooling transport and source attribution. The
capture command verifies a clean `main`, matching local `HEAD` and `origin/main`,
Roblox Studio availability, deterministic JSON evidence shape, deterministic
Markdown evidence output, and stable exit-code behavior.

Certification validation remains owned by
`Phase118CertificationContract.validateResult()`. The Node wrapper does not
duplicate runner-result validation or production-certification decisions.

## Phase 122 Studio Automation Bridge Validation

Phase 122 validates the bridge transport layer: supported phase identity, exact
runner path, exact contract path, exact gate attribute, source attribution posture,
Studio discovery results, execution method classification, blocked execution
status, evidence forwarding, and stable exit codes.

The bridge does not validate certification results. That remains owned by
`Phase118CertificationContract.validateResult()`.

## Phase 123 Structured Capture Validation

Phase 123 validates structured capture transport only: required envelope fields,
runner identity, runtime identity, suite field array shape, warning/failure array
shape, invalid capture rejection, partial capture rejection, corrupt capture
rejection, forwarding posture, source attribution preservation, and stable exit
codes.

The bridge does not duplicate `Phase118CertificationContract.validateResult()` or
`Phase118CertificationContract.canProductionCertify()`.

## Phase 124 MCP Activation Validation

Phase 124 validates activation prerequisites before runner invocation. Validation
covers Studio installation, official MCP command availability, repository opt-in,
supported execution method, supported structured result channel, source
attribution, activation refusal, duplicate activation prevention, and stable exit
codes.

## Phase 125 MCP Runner Binding Validation

Phase 125 validates binding posture before runner invocation. Validation covers
documented MCP command detection, runner command discovery, connected-session
availability, binding target identity, unsupported binding refusal, duplicate
binding prevention, wrapper consistency, and stable exit codes.

## Phase 126 Connected Studio MCP Session Validation

Phase 126 validates session posture before runner invocation. Validation covers
visible immutable session identity, supported interface, supported protocol,
healthy session state, source attribution, duplicate-session rejection,
unsupported-session rejection, disconnected-session classification, stable exit
codes, transition evidence, and bridge forwarding.

Studio installation, MCP command availability, and repository configuration are
not accepted as proof of a connected Studio MCP session.

## Phase 127 Studio MCP Runner Authority Validation

Phase 127 validates runner lifecycle orchestration only. Validation covers exact
request fields, immutable identity fields, allowed execution states, allowed status
values, source attribution posture, repository cleanliness, origin/main
synchronization, session authority readiness, binding authority readiness,
activation authority readiness, timeout classification, retry classification,
cancellation classification, blocked execution posture, and stable exit codes.

The authority rejects unsupported request fields and never transitions to `Ready`
unless every upstream authority reports ready.

## Phase 128 Runner Authority Contract Validation

Phase 128 validates the hardened Runner Authority contract. Validation covers
contract version compatibility, exact request field closure, exact diagnostics
field closure, audit field closure, immutable request identity, immutable execution
identity, immutable audit entries, legal lifecycle transitions, illegal transition
rejection, skipped transition rejection, cyclic transition rejection, duplicate
terminal rejection, terminal state immutability, timeout ownership, retry
ownership, cancellation ownership, deterministic serialization, deterministic
timestamps, stable exit codes, and authority isolation.
## Phase 129 Studio MCP Integration Contract Validation

Phase 129 validation is owned by
`automation/studio-mcp-integration-contract.mjs --self-check`. Coverage includes
protocol and contract version checks, handshake legality, required capabilities,
exact request/response/event/structured-result envelope schemas, deterministic
serialization, source attribution, authority isolation, and prohibited runtime
surface absence.

## Phase 130 Studio MCP Capability Negotiation Validation

Phase 130 validation is owned by
`automation/studio-capability-negotiation-authority.mjs --self-check`. Coverage
includes advertisement schemas, required and optional capabilities, dependency
graphs, circular dependency rejection, declared conflict rejection, immutable
profiles, audit records, lifecycle transitions, version compatibility,
deterministic serialization, and prohibited runtime surface absence.

## Phase 131 Studio MCP Execution Readiness Validation

Phase 131 validation is owned by
`automation/studio-execution-readiness-authority.mjs --self-check`. Coverage
includes readiness lifecycle, prerequisite aggregation, readiness decisions,
immutable profiles, blocking reasons, authority aggregation, version
compatibility, serialization, audit, deterministic exit codes, and prohibited
runtime surface absence.

## Phase 132 Studio MCP Execution Planning Validation

Phase 132 validation is owned by
`automation/studio-execution-planning-authority.mjs --self-check`. Coverage
includes planning lifecycle, execution graph validation, dependency validation,
stage ordering, checkpoint validation, immutable plans and graphs, exact plan
schema, deterministic serialization, deterministic exit codes, audit validation,
authority isolation, readiness consumption, and prohibited runtime surface
absence.

## Phase 133 Studio MCP Execution Orchestrator Validation

Phase 133 validation is owned by
`automation/studio-execution-orchestrator.mjs --self-check`. Coverage includes
orchestration lifecycle, orchestration graph validation, dependency validation,
stage ordering, execution context validation, retry policy validation,
cancellation policy validation, immutable orchestration models, deterministic
serialization, deterministic exit codes, audit validation, authority isolation,
planning consumption, and prohibited runtime surface absence.

## Phase 134 Studio MCP Execution Request Authority Validation

Phase 134 validation is owned by
`automation/studio-execution-request-authority.mjs --self-check`. Coverage
includes request lifecycle validation, exact request schema validation, identifier
validation, duplicate identifier rejection, orchestration compatibility, readiness
compatibility, capability compatibility, immutable request publication,
deterministic serialization, deterministic timestamps, deterministic exit codes,
diagnostics validation, audit validation, authority isolation, orchestration
consumption, and prohibited runtime surface absence.

## Phase 135 Studio MCP Execution Dispatch Authority Validation

Phase 135 validation is owned by
`automation/studio-execution-dispatch-authority.mjs --self-check`. Coverage
includes dispatch lifecycle validation, exact dispatch schema validation,
identifier validation, duplicate identifier rejection, eligibility validation,
blocked-state truthfulness, execution intent consumption, request compatibility,
orchestration compatibility, planning compatibility, readiness compatibility,
capability compatibility, protocol compatibility, immutable dispatch publication,
deterministic serialization, deterministic timestamps, deterministic exit codes,
diagnostics validation, audit validation, authority isolation, request authority
consumption, and prohibited runtime surface absence.

## Phase 136 Studio MCP External Execution Boundary Validation

Phase 136 validation is owned by
`automation/studio-external-execution-boundary.mjs --self-check`. Coverage
includes boundary lifecycle validation, handoff schema validation, external
consumer contract schema validation, correlation validation across Phases 131
through 136, boundary eligibility truthfulness, ownership-transfer truthfulness,
diagnostics validation, audit validation, deterministic serialization, stable
blocked exit codes, authority isolation, upstream regression compatibility, and
prohibited execution, transport, evidence, persistence, analytics, telemetry, and
certification surfaces.

## Phase 137 Studio MCP External Consumer Contract Authority Validation

Phase 137 validation is owned by
`automation/studio-external-consumer-contract-authority.mjs --self-check`.
Coverage includes contract lifecycle validation, exact top-level schema
validation, exact nested acknowledgement, structured-result, runtime-evidence,
correlation, failure, and compatibility-policy schema validation, consumer type
validation, compatibility-state validation, availability-state validation,
version preservation, evolution policy classification, diagnostics validation,
audit validation, deterministic serialization, stable blocked exit codes,
authority isolation, Phase 136 through Phase 132 regression compatibility, and
prohibited execution, transport, consumer discovery, authentication, evidence,
persistence, analytics, telemetry, and certification surfaces.

## Phase 138 Studio MCP External Consumer Manifest Authority Validation

Phase 138 validation is owned by
`automation/studio-external-consumer-manifest-authority.mjs --self-check`.
Coverage includes manifest lifecycle validation, exact manifest schema
validation, immutable manifest publication, consumer catalog validation,
compatibility matrix validation, duplicate identifier rejection, diagnostics
validation, audit validation, deterministic identifiers, deterministic
serialization, deterministic ordering, stable blocked exit codes, rerun
stability, authority isolation, Phase 137 through Phase 132 regression
compatibility, and prohibited networking, Studio, Runner, transport, execution,
runtime evidence, certification, gameplay, persistence, analytics, and telemetry
surfaces.

## Phase 139 Studio MCP Consumer Compatibility Authority Validation

Phase 139 validation is owned by
`automation/studio-consumer-compatibility-authority.mjs --self-check`. Coverage
includes lifecycle validation, exact candidate profile schema validation, exact
compatibility evaluation schema validation, exact component and manifest
recognition schemas, manifest recognition, protocol, dispatch, boundary,
capability, acknowledgement, result, evidence, and failure schema evaluations,
blocked runtime and repository ownership preservation, immutable publication,
diagnostics, audit, deterministic results, stable blocked exit codes, Phase 138
through Phase 132 regression compatibility, and prohibited networking, Studio,
Runner, transport, MCP communication, consumer discovery, authentication,
runtime evidence, certification, gameplay, persistence, analytics, and telemetry
surfaces.

## Phase 140 Studio MCP External Execution Envelope Authority Validation

Phase 140 validation is owned by
`automation/studio-external-execution-envelope-authority.mjs --self-check`.
Coverage includes envelope lifecycle validation, exact envelope schema
validation, exact nested execution intent, dispatch, boundary, consumer contract,
manifest, compatibility, and correlation snapshot schemas, strict upstream
correlation, upstream version and state preservation, blocked execution and
repository ownership preservation, future transport readiness rejection, deep
immutability, diagnostics, audit, deterministic serialization, stable blocked
exit codes, Phase 139 through Phase 132 regression compatibility, and prohibited
consumer discovery, connection attempts, authentication, process execution,
networking, transport, MCP communication, Studio execution, Runner invocation,
envelope transmission, runtime evidence, certification, gameplay, persistence,
analytics, and telemetry surfaces.

## Phase 141 Studio MCP External Envelope Transport Contract Authority Validation

Phase 141 validation is owned by
`automation/studio-envelope-transport-contract-authority.mjs --self-check`.
Coverage includes transport contract lifecycle validation, exact top-level
schema validation, delivery contract validation, acknowledgement contract
validation, retry contract validation, transport error contract validation,
transport capability contract validation, Phase 140 envelope correlation,
immutable publication, diagnostics, audit, deterministic serialization, stable
blocked exit codes, Phase 140 regression compatibility, and prohibited transport
or runtime surfaces.

## Phase 143 Studio MCP External Transport Compatibility Authority Validation

Phase 143 validation is owned by
`automation/studio-external-transport-compatibility-authority.mjs --self-check`.
Coverage includes compatibility lifecycle validation, exact evaluation and
correlation schemas, upstream ID and version preservation, component result
classification, overall compatibility classification, transport availability
preservation, execution eligibility classification, blocked execution posture,
deep immutability, diagnostics, audit, deterministic serialization, stable
blocked exit codes, Phase 142 through Phase 140 regression compatibility, and
prohibited transport or runtime surfaces.

## Phase 144 Studio MCP External Transport Implementation Contract Authority Validation

Phase 144 validation is owned by
`automation/studio-external-transport-implementation-contract-authority.mjs --self-check`.
Coverage includes implementation contract lifecycle validation, exact top-level
and nested schemas, upstream ID and version preservation, compatibility
preconditions, lifecycle definitions, checkpoint definitions, failure definitions,
boundary ownership definitions, readiness classification, blocked execution
posture, deep immutability, diagnostics, audit, deterministic serialization,
stable blocked exit codes, Phase 143 through Phase 140 regression compatibility,
and prohibited implementation loading, execution, transport, networking, runtime
evidence, and certification surfaces.

## Phase 142 Studio MCP External Envelope Transport Capability Authority Validation

Phase 142 validation is owned by
`automation/studio-envelope-transport-capability-authority.mjs --self-check`.
Coverage includes capability lifecycle validation, exact capability profile
schema validation, supported upstream version validation, classification
validation, immutable publication, diagnostics, audit, deterministic
serialization, stable blocked exit codes, Phase 141 and Phase 140 regression
compatibility, and prohibited transport or runtime surfaces.
## Phase 145 Implementation Readiness Validation

Phase 145 validates the exact implementation readiness evaluation schema,
correlation snapshot schema, lifecycle readiness, checkpoint readiness,
failure-contract readiness, boundary readiness, overall readiness
classification, future validation eligibility, diagnostics, audit, immutability,
deterministic serialization, and blocked execution posture.

Validation rejects unknown or missing fields, unsupported enum values, duplicate
or drifted identifiers, unsupported upstream versions, nested schema drift,
mutable publication, transport availability claims, executable eligibility
claims, and any transfer of networking, credentials, external execution, or
runtime evidence ownership into repository tooling.

Normal execution returns exit code `2` because structural readiness is published
while implementation and transport remain unavailable.
