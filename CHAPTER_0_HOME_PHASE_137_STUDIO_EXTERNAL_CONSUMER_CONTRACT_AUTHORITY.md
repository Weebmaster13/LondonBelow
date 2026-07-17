# Chapter 0 Home Phase 137 Studio MCP External Consumer Contract Authority

Phase 137 adds the repository-owned Studio MCP External Consumer Contract
Authority in `automation/studio-external-consumer-contract-authority.mjs`.

## Mission

The authority defines the complete immutable contract a future external Studio
MCP consumer must satisfy before it can receive an execution handoff. A published
contract is a schema and policy artifact only. It is not consumer discovery,
consumer connection, execution, evidence, or certification.

## Ownership

The authority owns consumer contract identity, contract versioning, exact schema
validation, capability requirements, acknowledgement requirements,
structured-result requirements, runtime-evidence delivery requirements,
correlation requirements, failure requirements, compatibility policy, lifecycle,
diagnostics, audit, publication, and deterministic evolution policy.

It does not own external consumer discovery, identity resolution, authentication,
authorization credentials, transport, networking, Studio execution, Runner
invocation, dispatch transmission, ownership transfer, acknowledgement capture,
result capture, runtime evidence, certification, gameplay, persistence,
rendering, analytics, or telemetry.

## Lifecycle

Allowed success path:

`Idle -> ReceiveBoundaryContract -> ValidateContractDefinition ->
BuildConsumerContract -> ValidateCompatibilityPolicy -> FreezeConsumerContract ->
ConsumerContractPublished`

Allowed failure paths are `MissingBoundaryContract`, `ContractRejected`,
`ContractConstructionFailed`, `CompatibilityRejected`, and `FreezeRejected`.
Illegal transitions, skipped transitions, cycles, terminal mutation, and repeated
terminal transitions reject.

## Top-Level Schema

Published contracts contain exactly:

`consumerContractId`, `consumerContractVersion`, `consumerType`,
`boundaryContractId`, `boundaryVersion`, `acceptedDispatchVersion`,
`requiredProtocolVersion`, `minimumCapabilityProfileVersion`,
`executionAcknowledgementContract`, `structuredResultContract`,
`runtimeEvidenceContract`, `correlationContract`, `failureContract`,
`compatibilityPolicy`, `validationState`, and `timestamp`.

The only Phase 137 consumer type is `StudioMCPExternalImplementation`. This is a
descriptive contract type and does not prove a consumer exists.

## Nested Contracts

The acknowledgement contract requires future accepted and rejected acknowledgement
states, complete boundary/request/dispatch/consumer correlation, and future
consumer instance identity. Phase 137 never creates a consumer instance identity
or synthesizes an acknowledgement.

The structured-result contract requires future result identity, acknowledgement
identity, boundary/request/dispatch correlation, execution state, payload,
diagnostics, and timestamp. Phase 137 never creates result IDs, creates result
payloads, captures Studio diagnostics, or sets `structuredResultCaptured = true`.

The runtime-evidence contract requires future evidence envelopes, evidence
correlation, execution results, provenance, integrity, and timestamp.
`certificationEligibleByDefault` is always `false`. Phase 137 never generates,
validates, synthesizes, or certifies runtime evidence.

The correlation contract requires readiness, execution plan, orchestration,
request, dispatch, boundary, consumer contract, acknowledgement, result, and
strict-ordering correlation.

The failure contract defines future failure categories only:
`ContractRejected`, `ConsumerUnavailable`, `ProtocolMismatch`,
`CapabilityMismatch`, `ExecutionRejected`, `ExecutionFailed`, `ResultInvalid`,
and `EvidenceInvalid`. Phase 137 does not claim any runtime failure occurred.

## Compatibility Policy

The policy requires exact protocol, dispatch-version, boundary-version, and
schema matching; minimum compatible capability profile version; unknown major
version rejection; declared compatible minor-version tolerance; and unknown-field
rejection.

Compatibility states are `NotEvaluated`, `DefinitionCompatible`, and
`DefinitionIncompatible`. Normal Phase 137 output is `DefinitionCompatible`,
meaning the repository-owned contract definition is internally valid against the
Phase 136 descriptive contract. It does not mean execution may proceed.

External consumer availability states are `NotDiscovered`, `NotConnected`, and
`ContractOnly`. Normal Phase 137 output is `ContractOnly`; no connected state is
defined.

## Diagnostics And Audit

Diagnostics contain exactly consumer contract version, contract state, boundary
state, boundary eligibility, ownership-transfer state, consumer availability
state, compatibility state, validation state, failure reason, and timestamp.
They are tooling-only and are not Studio diagnostics, runtime evidence, or
certification evidence.

Audit entries contain exactly consumer contract ID, boundary ID, dispatch ID,
authority ID, contract state, consumer availability state, compatibility state,
validation state, timestamp, and contract version. Audit history is append-only,
immutable, deterministic, ordered, duplicate-resistant, and authority-scoped.

## Evolution Policy

Documentation-only clarification is `PatchCompatible`. Optional field additions
and enum expansion require explicit minor compatibility declarations. Field
removal, field renaming, required field type changes, enum narrowing,
correlation requirement changes, evidence requirement changes, unknown major
versions, and undeclared compatibility are breaking or rejected. Phase 137 adds
no migration system.

## Integration Graph

Phase 137 consumes Phase 136 boundary handoff packages read-only and extends the
published descriptive consumer contract into a repository-owned authority model.
The future external consumer implementation remains documentation-only.

## Blocked Runtime Result

Normal execution returns exit code `2` and status `executionBlocked`. It preserves
`SESSION_NOT_VISIBLE`, `boundaryEligibility = Blocked`,
`ownershipTransferState = RepositoryOwned`, `runnerInvoked = false`,
`structuredResultCaptured = false`, and no runtime evidence.

## Certification Boundary

Phase 137 is Production Candidate only. It does not use or duplicate the Phase
118 certification contract, does not produce runtime evidence, and cannot advance
the latest Production Certified milestone beyond Phase 108.

## Acceptance Criteria

- `npm run london:studio:consumer-contract:phase137:selfcheck` passes.
- Normal execution returns `executionBlocked` with exit code `2`.
- Phase 136, Phase 135, Phase 134, Phase 133, and Phase 132 regression
  self-checks pass.
- Static validation, Rojo verification, diff checks, and forbidden API scan pass.
- Generated artifacts are removed before commit.
