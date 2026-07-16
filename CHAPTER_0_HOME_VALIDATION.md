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
interaction has not been accepted, and non-optional facts whose source progression
stage is not current.
