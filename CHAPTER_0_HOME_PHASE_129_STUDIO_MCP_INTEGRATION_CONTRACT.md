# Chapter 0 Home Phase 129 Studio MCP Integration Contract

Phase 129 creates `automation/studio-mcp-integration-contract.mjs`, the sole
repository authority for the Studio MCP integration protocol contract. It defines
what an external Studio MCP implementation must advertise and serialize before
London Engine will accept communication.

This phase does not execute Studio, discover sessions, invoke runners, capture
runtime results, decide certification, mutate gameplay, implement networking
transport, write persistence, or synthesize evidence.

## Protocol Metadata

- `protocolVersion`: `1.0.0`
- `contractVersion`: `1.0.0`
- `schemaVersion`: `1`
- `compatibilityVersion`: `1`

Unsupported versions reject before communication. Version metadata is immutable
during evaluation.

## Handshake

Legal success path:

`Idle -> Discovery -> CapabilityExchange -> CompatibilityValidation -> SourceValidation -> HandshakeAccepted`

Legal failure paths:

- `Discovery -> HandshakeRejected`
- `CapabilityExchange -> UnsupportedVersion`
- `CompatibilityValidation -> IncompatibleCapabilities`
- `SourceValidation -> InvalidSource`

No undocumented transition is accepted.

## Capabilities

External implementations must explicitly advertise:

- `SessionIdentity`
- `RunnerExecution`
- `StructuredResults`
- `EvidenceTransport`
- `Heartbeat`
- `VersionMetadata`

Missing or duplicate capabilities reject. Capabilities are never inferred from
Studio installation, MCP command presence, or repository configuration.

## Envelopes

Request envelopes contain exactly `protocolVersion`, `contractVersion`,
`requestId`, `authorityId`, `runnerId`, `phase`, `repositoryRevision`,
`timestamp`, `payload`, and `sourceAttribution`.

Response envelopes contain exactly `protocolVersion`, `responseId`, `requestId`,
`executionId`, `status`, `result`, `diagnostics`, and `timestamp`.

Event envelopes contain exactly `eventId`, `eventType`, `authority`, `timestamp`,
`payload`, and `sequence`. Sequence values must be monotonic.

Structured result envelopes contain execution identity, authority identity,
request identity, result classification, diagnostics, timestamps, audit
reference, and source attribution. Gameplay data and certification decisions are
forbidden.

## Compatibility

Compatibility validation checks protocol version, contract version, schema
version, authority compatibility, required capabilities, exact envelope fields,
and deterministic serialization.

Allowed protocol failures are deterministic:

- `UnsupportedProtocol`
- `UnsupportedContract`
- `CapabilityMissing`
- `InvalidHandshake`
- `InvalidEnvelope`
- `SchemaMismatch`
- `SerializationFailure`
- `InvalidSource`
- `UnknownAuthority`

## Serialization

Serialization is frozen around deterministic property ordering, stable numeric
formatting through JSON, UTF-8 encoding, immutable identity, and reproducible
output. Unsupported values, cycles, functions, symbols, `undefined`, and
non-finite numbers reject.

## Integration Graph

The contract consumes, and bypasses none of:

- Phase 121 Evidence Transport
- Phase 122 Bridge
- Phase 124 Activation Authority
- Phase 125 Binding Authority
- Phase 126 Session Authority
- Phase 127 Runner Authority

## Current Result

The current repository still reports `SESSION_NOT_VISIBLE`, `executionBlocked`,
`runnerInvoked = false`, and `structuredResultCaptured = false`. Phase 129 is a
Production Candidate only. Phase 108 remains the latest Production Certified
milestone.

## Acceptance

Acceptance requires the integration contract authority to validate protocol
metadata, handshake transitions, required capabilities, envelope schemas,
serialization, diagnostics, source attribution, authority isolation, and boundary
preservation while refusing unsupported external implementations before any
runner invocation.
