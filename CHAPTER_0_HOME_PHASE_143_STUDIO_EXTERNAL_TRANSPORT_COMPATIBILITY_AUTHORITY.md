# Chapter 0 Home Phase 143 Studio MCP External Transport Compatibility Authority

Phase 143 adds the repository-owned Studio MCP External Transport Compatibility
Authority in `automation/studio-external-transport-compatibility-authority.mjs`.

## Mission

The authority evaluates whether the repository-owned Phase 142 transport
capability profile satisfies the immutable obligations defined by the Phase 141
transport contract. It performs definition-level compatibility evaluation only.

Definition compatibility is not implementation verification. Compatibility
publication is not transport readiness.

## Ownership

The authority owns compatibility evaluation identity and versioning,
transport-contract and capability-profile correlation, component compatibility
results, overall transport compatibility classification, transport availability
classification, execution eligibility classification, immutable publication,
diagnostics, audit, and deterministic serialization.

It does not own transport contract policy, capability declarations, transport
implementation, network discovery, endpoints, HTTP, TCP, UDP, sockets,
WebSockets, authentication, authorization, credentials, MCP communication,
envelope transmission, acknowledgement reception, Studio execution, Runner
invocation, structured result capture, runtime evidence, certification,
gameplay, persistence, rendering, analytics, or telemetry.

## Upstream Authorities

Phase 143 consumes these authorities read-only:

- Phase 140 External Execution Envelope Authority.
- Phase 141 External Envelope Transport Contract Authority.
- Phase 142 External Envelope Transport Capability Authority.

No upstream ownership migrates into Phase 143.

## Lifecycle

Success path:

`Idle -> ReceiveTransportContract -> ReceiveCapabilityProfile ->
ResolveCompatibilityInputs -> ValidateCompatibilityCorrelation ->
EvaluateTransportCompatibility -> FreezeCompatibilityEvaluation ->
TransportCompatibilityPublished`

Failure paths are `MissingTransportContract`, `MissingCapabilityProfile`,
`CompatibilityInputResolutionFailed`, `CompatibilityCorrelationRejected`,
`CompatibilityEvaluationFailed`, and `FreezeRejected`.

Illegal transitions, skipped transitions, cyclic transitions, repeated terminal
transitions, and terminal mutation reject.

## Evaluation Schema

Published evaluations contain exactly `compatibilityEvaluationId`,
`compatibilityEvaluationVersion`, `transportContractId`, `capabilityId`,
`transportInterfaceResult`, `envelopeVersionResult`,
`acknowledgementVersionResult`, `retryPolicyResult`, `transportErrorResult`,
`capabilityProfileResult`, `overallTransportCompatibility`,
`transportAvailabilityState`, `executionEligibility`, `correlationSnapshot`,
`validationState`, and `timestamp`.

Unknown fields, missing fields, duplicate identifiers, unsupported enum values,
mutable publication, nested unknown fields, nested missing fields, upstream ID
drift, and upstream version drift reject.

## Component Results

Each component result is exactly `Compatible`, `Incompatible`, or `NotDeclared`.
Components cover transport interface, envelope version, acknowledgement schema,
retry policy, transport error schema, and capability profile classification.

`Compatible` means the declaration satisfies the contract requirement.
`Incompatible` means a declaration conflicts with the contract. `NotDeclared`
means required metadata is absent. No component result implies implementation
validation.

## Compatibility Semantics

Overall compatibility is `CompatibleDefinition`, `IncompatibleDefinition`, or
`IncompleteDefinition`. Normal Phase 143 output is `CompatibleDefinition`.

Transport availability is `TransportUnavailable` in normal Phase 143 output.
`TransportAvailable` is rejected because no transport exists.

Execution eligibility is `DefinitionCompatibleButUnavailable` in normal output.
No Phase 143 result permits execution.

## Correlation Rules

The correlation snapshot contains exactly `transportContractId`, `capabilityId`,
`requiredEnvelopeVersion`, `supportedEnvelopeVersions`,
`transportInterfaceVersion`, `supportedInterfaceVersions`, and
`strictCorrelationValidated`.

`strictCorrelationValidated = true` means repository metadata correlation passed.
It does not mean a real external implementation was correlated.

## Diagnostics And Audit

Diagnostics expose compatibility evaluation version, compatibility state,
overall transport compatibility, transport availability state, execution
eligibility, execution blocked posture, validation state, failure reason, and
timestamp. Normal diagnostics are `TransportCompatibilityPublished`,
`CompatibleDefinition`, `TransportUnavailable`, and
`DefinitionCompatibleButUnavailable`.

Audit entries capture compatibility evaluation ID, transport contract ID,
capability ID, authority ID, compatibility state, overall compatibility,
transport availability, execution eligibility, timestamp, and compatibility
evaluation version. Audit output is append-only, immutable, deterministic,
ordered, duplicate-resistant, and authority-scoped.

## Blocked Runtime Result

Normal execution returns exit code `2` and status `executionBlocked`. Phase 143
does not validate a real implementation, discover endpoints, authenticate,
create transport, transmit envelopes, receive acknowledgements, communicate with
MCP, execute Studio, invoke the Runner, synthesize structured results, generate
runtime evidence, or decide certification.

## Acceptance Criteria

- `npm run london:studio:transport-compatibility:phase143:selfcheck` passes.
- Normal execution returns `executionBlocked` with exit code `2`.
- Phase 142, Phase 141, and Phase 140 regression self-checks pass.
- Static validation, Rojo verification, diff checks, and forbidden API scan pass.
- Generated artifacts are removed before commit.
