# Chapter 0 Home Phase 136 Studio External Execution Boundary

Phase 136 creates `automation/studio-external-execution-boundary.mjs`, the sole
repository authority for Studio MCP external execution handoff construction and
publication.

This authority does not execute Studio, invoke the runner, create transport,
communicate with MCP, discover an external consumer, capture runtime evidence,
certify results, write persistence, render content, or mutate gameplay. It
consumes the Phase 135 execution dispatch read-only and publishes an immutable
handoff package that defines where repository ownership ends.

## Ownership

The authority owns boundary identity, boundary versioning, dispatch intake,
handoff package construction, handoff lifecycle, ownership-transfer metadata,
boundary eligibility, compatibility validation, immutable boundary publication,
boundary diagnostics, boundary audit, transfer-condition metadata, and the
descriptive external-consumer contract.

It does not own Studio execution, runner invocation, external process invocation,
networking transport, MCP communication, session creation, request construction,
dispatch classification ownership, orchestration, planning, readiness evaluation,
capability negotiation, protocol ownership, result capture, runtime evidence,
certification, gameplay, persistence, rendering, analytics, or telemetry.

## Lifecycle

Success path:

`Idle -> ReceiveDispatch -> ValidateBoundaryCompatibility -> ConstructHandoffPackage -> FreezeBoundary -> BoundaryPublished`

Failure paths:

- `ReceiveDispatch -> MissingDispatch`
- `ValidateBoundaryCompatibility -> BoundaryIneligible`
- `ValidateBoundaryCompatibility -> BoundaryRejected`
- `ConstructHandoffPackage -> HandoffConstructionFailed`
- `FreezeBoundary -> FreezeRejected`

Illegal, skipped, cyclic, repeated-terminal, and terminal-mutating transitions
reject.

## Handoff Schema

Every handoff package contains exactly:

- `boundaryId`
- `boundaryVersion`
- `dispatchId`
- `requestId`
- `orchestrationId`
- `executionPlanId`
- `readinessId`
- `protocolVersion`
- `capabilityProfileId`
- `executionIntent`
- `dispatchEligibility`
- `boundaryEligibility`
- `ownershipTransferState`
- `externalConsumerContract`
- `validationState`
- `timestamp`

Unknown fields reject. Missing fields reject. Duplicate identifiers reject.
Upstream values must match the consumed Phase 135 dispatch artifact.

## Boundary Eligibility

Supported boundary eligibility values are:

- `Blocked`
- `ReadyForExternalConsumer`
- `TransferredToExternalConsumer`

These values are metadata classifications only. They never initiate Studio
execution, runner invocation, MCP communication, transport creation, process
spawning, result capture, evidence generation, or certification.

Current dispatch truth is `dispatchEligibility = Blocked`, so Phase 136 publishes
`boundaryEligibility = Blocked`.

## Ownership Transfer

Supported ownership-transfer states are:

- `RepositoryOwned`
- `TransferPrepared`
- `ExternalConsumerOwned`

Current normal execution publishes `RepositoryOwned` because no external consumer
exists and execution remains blocked. `TransferPrepared` requires
`ReadyForExternalConsumer`; `ExternalConsumerOwned` requires
`TransferredToExternalConsumer`.

## External Consumer Contract

The handoff package contains an immutable descriptive external-consumer contract
with exactly:

- `contractId`
- `contractVersion`
- `consumerType`
- `requiredProtocolVersion`
- `acceptedDispatchVersion`
- `requestCorrelationRequired`
- `structuredResultRequired`
- `runtimeEvidenceRequired`
- `executionAcknowledgementRequired`

The only supported consumer type is `StudioMCPExternalImplementation`.

This contract is descriptive only. It does not discover, connect to,
authenticate, launch, poll, send dispatch to, or receive results from any external
consumer.

## Correlation

The boundary validates correlation across readiness id, execution plan id,
orchestration id, request id, dispatch id, and boundary id. Validation rejects
missing identifiers, duplicated correlation identities, mismatched upstream
identifiers, protocol mismatches, and capability-profile mismatches.

Phase 136 validates correlation but does not regenerate upstream identities.

## Diagnostics

Diagnostics are tooling-only and expose boundary version, boundary state, dispatch
state, dispatch eligibility, boundary eligibility, ownership-transfer state,
external consumer state, validation state, compatibility state, failure reason,
and timestamp.

Diagnostics are not runtime evidence and cannot certify Chapter 0.

## Audit

Audit entries include boundary id, dispatch id, request id, authority id, boundary
state, boundary eligibility, ownership-transfer state, external consumer state,
timestamp, and contract version. Audit history is append-only, immutable,
deterministic, ordered, duplicate-resistant, and authority-scoped.

## Integration Graph

External Execution Boundary consumes the established authority chain:

`Evidence Transport -> Bridge -> Activation -> Binding -> Session -> Runner -> Integration Contract -> Capability Negotiation -> Execution Readiness -> Execution Planning -> Execution Orchestrator -> Execution Request -> Execution Dispatch -> External Execution Boundary -> Future External Studio MCP Implementation`

The final node is documentation-only and is not implemented in Phase 136.

## Current Result

No connected Studio MCP session identity is visible and execution remains blocked.
The authority publishes deterministic boundary artifacts while preserving
`SESSION_NOT_VISIBLE`, `executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

Phase 136 is Production Candidate only. Phase 108 remains the latest Production
Certified milestone.

## Acceptance

Phase 136 is acceptable only when the boundary authority exists, consumes Phase
135 dispatch artifacts read-only, validates and freezes deterministic handoff
packages, publishes the exact immutable external-consumer contract, validates
correlation across Phases 131 through 136, preserves dispatch eligibility without
reinterpretation, keeps boundary eligibility `Blocked`, keeps ownership
`RepositoryOwned`, fabricates no external consumer, introduces no execution or
transport capability, and keeps the repository truthful about blocked Studio MCP
execution.
