# Chapter 0 Home Phase 142 Studio MCP External Envelope Transport Capability Authority

Phase 142 adds the repository-owned Studio MCP External Envelope Transport
Capability Authority in
`automation/studio-envelope-transport-capability-authority.mjs`.

## Mission

The authority publishes immutable capability declarations describing what a
future transport implementation may advertise about itself. It defines
capability metadata only.

Capability publication is not transport availability. Capability declaration is
not implementation validation. A `DefinitionOnly` capability profile is not a
connected or executable transport.

## Ownership

The authority owns capability identity, capability version,
capability-profile version, supported transport contract versions, supported
envelope versions, supported acknowledgement versions, supported retry policy
versions, supported transport error versions, supported interface versions,
capability classification, diagnostics, audit, and immutable publication.

It does not own transport implementation, networking, HTTP, TCP, UDP, sockets,
MCP communication, authentication, authorization, endpoint discovery, Studio
execution, Runner invocation, transmission, acknowledgement reception, runtime
evidence, certification, gameplay, persistence, rendering, analytics, or
telemetry.

## Lifecycle

Success path:

`Idle -> ReceiveTransportContract -> ResolveCapabilityRequirements ->
ValidateCapabilityProfile -> ConstructCapabilityProfile ->
FreezeCapabilityProfile -> CapabilityProfilePublished`

Failure paths are `MissingTransportContract`, `CapabilityRequirementFailure`,
`CapabilityRejected`, `CapabilityConstructionFailed`, and `FreezeRejected`.

Illegal transitions, skipped transitions, cyclic transitions, and terminal
mutation reject.

## Capability Profile Schema

Published capability profiles contain exactly `capabilityId`,
`capabilityVersion`, `capabilityProfileVersion`,
`supportedTransportContractVersions`, `supportedEnvelopeVersions`,
`supportedAcknowledgementVersions`, `supportedRetryPolicyVersions`,
`supportedTransportErrorVersions`, `supportedInterfaceVersions`,
`capabilityClassification`, `validationState`, and `timestamp`.

Unknown fields, missing fields, duplicate IDs, unsupported versions, and
uncorrelated transport contract identities reject.

## Classification

Allowed classification values are `DefinitionOnly`, `ImplementationVerified`,
and `Deprecated`. Normal Phase 142 publication is `DefinitionOnly`.
`ImplementationVerified` is rejected in Phase 142 because no implementation is
executed or validated.

## Version Declarations

Capability declarations may only reference versions already defined by the Phase
141 transport contract and Phase 140 execution envelope authorities. They may not
invent transport interfaces, envelope versions, acknowledgement schemas, retry
policies, or error schemas.

## Diagnostics And Audit

Diagnostics expose capability version, capability state, capability
classification, validation state, failure reason, and timestamp. Normal
diagnostics are `CapabilityProfilePublished` and `DefinitionOnly`.

Audit entries capture capability ID, transport contract ID, authority ID,
capability state, validation state, and timestamp. Audit output is append-only,
immutable, deterministic, and ordered.

## Blocked Runtime Result

Normal execution returns exit code `2` and status `executionBlocked`. Phase 142
does not create transport, transmit envelopes, discover endpoints, authenticate,
communicate with MCP, execute Studio, invoke the Runner, receive
acknowledgements, capture structured results, generate runtime evidence, or
decide certification.

## Acceptance Criteria

- `npm run london:studio:transport-capability:phase142:selfcheck` passes.
- Normal execution returns `executionBlocked` with exit code `2`.
- Phase 141 and Phase 140 regression self-checks pass.
- Static validation, Rojo verification, diff checks, and forbidden API scan pass.
- Generated artifacts are removed before commit.
