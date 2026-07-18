# Chapter 0 Home Phase 141 Studio MCP External Envelope Transport Contract Authority

Phase 141 adds the repository-owned Studio MCP External Envelope Transport
Contract Authority in `automation/studio-envelope-transport-contract-authority.mjs`.

## Mission

The authority defines the immutable contract a future external envelope transport
implementation must satisfy before a Phase 140 execution envelope can ever leave
the repository. It publishes definitions only.

Transport contract publication is not transport. Delivery contract definition is
not delivery. Acknowledgement contract definition is not acknowledgement
reception. Capability declaration is not a connected capability.

## Ownership

The authority owns transport contract identity, versioning, interface version,
required and supported envelope versions, delivery contract, acknowledgement
contract, retry contract, transport capability contract, transport error
contract, validation state, immutable publication, diagnostics, audit, and
deterministic serialization.

It does not own networking, HTTP, TCP, UDP, WebSockets, sockets, MCP
communication, authentication, authorization, credential handling, endpoint
discovery, Studio execution, Runner invocation, envelope transmission,
acknowledgement reception, runtime evidence, certification, gameplay,
persistence, rendering, analytics, or telemetry.

## Lifecycle

Success path:

`Idle -> ReceiveExecutionEnvelope -> ResolveTransportRequirements ->
ValidateTransportContract -> ConstructTransportContract ->
FreezeTransportContract -> TransportContractPublished`

Failure paths are `MissingExecutionEnvelope`, `TransportRequirementFailure`,
`TransportContractRejected`, `TransportConstructionFailed`, and
`FreezeRejected`.

Illegal transitions, skipped transitions, cyclic transitions, and terminal
mutation reject.

## Contract Schema

Published transport contracts contain exactly `transportContractId`,
`transportContractVersion`, `transportInterfaceVersion`,
`requiredEnvelopeVersion`, `supportedEnvelopeVersion`, `deliveryContract`,
`acknowledgementContract`, `retryContract`, `transportCapabilityContract`,
`transportErrorContract`, `validationState`, and `timestamp`.

Unknown fields, missing fields, duplicate IDs, unsupported versions, and
uncorrelated envelope identities reject.

## Subcontracts

The delivery contract defines `FutureExternalTransport`,
`DeterministicEnvelopeOrder`, `DefinitionOnly`, required correlation, and an
immutable-envelope requirement.

The acknowledgement contract defines schema version, envelope-ID correlation,
and the descriptive states `Accepted`, `Rejected`, and `Unavailable`.

The retry contract defines policy only. Phase 141 publishes `retrySupported =
false` and `retryClassification = None`.

The transport error contract defines descriptive error codes:
`TransportUnavailable`, `EndpointUnavailable`, `EnvelopeRejected`,
`VersionMismatch`, `ContractMismatch`, `AuthenticationUnavailable`, and
`UnknownTransportFailure`.

The capability contract defines version compatibility metadata only. It does not
create or imply a transport implementation.

## Diagnostics And Audit

Diagnostics expose transport contract version, transport contract state,
transport availability state, validation state, failure reason, and timestamp.
Normal diagnostics are `TransportContractPublished` and
`TransportUnavailable`.

Audit entries capture transport contract ID, envelope ID, authority ID, transport
state, validation state, and timestamp. Audit output is append-only, immutable,
deterministic, and ordered.

## Blocked Runtime Result

Normal execution returns exit code `2` and status `executionBlocked`. Phase 141
does not transmit envelopes, create transport, discover endpoints, authenticate,
communicate with MCP, execute Studio, invoke the Runner, receive
acknowledgements, capture structured results, generate runtime evidence, or
decide certification.

## Acceptance Criteria

- `npm run london:studio:transport-contract:phase141:selfcheck` passes.
- Normal execution returns `executionBlocked` with exit code `2`.
- Phase 140 through Phase 135 regression self-checks pass.
- Static validation, Rojo verification, diff checks, and forbidden API scan pass.
- Generated artifacts are removed before commit.
