# Chapter 0 Home Phase 135 Studio Execution Dispatch Authority

Phase 135 creates `automation/studio-execution-dispatch-authority.mjs`, the sole
repository authority for Studio MCP execution dispatch preparation.

This authority does not execute Studio, invoke the runner, open transport,
simulate MCP communication, capture runtime evidence, certify results, write
persistence, render content, or mutate gameplay. It consumes the Phase 134
execution request read-only and publishes an immutable dispatch artifact.

## Ownership

The authority owns execution request intake, dispatch identity, dispatch
lifecycle, dispatch eligibility, exact dispatch schema, compatibility validation,
diagnostics, audit, dispatch publication, and dispatch versioning.

It does not own request construction, orchestration, planning, readiness
evaluation, capability negotiation, protocol definition, Studio execution, runner
execution, networking transport, runtime evidence, certification, gameplay,
persistence, or rendering.

## Lifecycle

Success path:

`Idle -> ReceiveExecutionRequest -> ValidateDispatchEligibility -> BuildDispatch -> FreezeDispatch -> DispatchPublished`

Failure paths:

- `ReceiveExecutionRequest -> MissingExecutionRequest`
- `ValidateDispatchEligibility -> DispatchIneligible`
- `BuildDispatch -> DispatchConstructionFailed`
- `FreezeDispatch -> FreezeRejected`

Illegal, skipped, cyclic, and terminal-mutating transitions reject.

## Dispatch Schema

Every dispatch artifact contains exactly:

- `dispatchId`
- `dispatchVersion`
- `requestId`
- `orchestrationId`
- `executionPlanId`
- `readinessId`
- `protocolVersion`
- `capabilityProfileId`
- `executionIntent`
- `dispatchEligibility`
- `validationState`
- `timestamp`

Unknown fields reject. Missing fields reject. Duplicate identifiers reject.
Dispatch artifacts are frozen before publication.

## Dispatch Eligibility

Supported eligibility values are:

- `Blocked`
- `AwaitingExternalBoundary`
- `EligibleForExternalBoundary`

These values classify the dispatch artifact only. They never initiate Studio
execution, runner invocation, transport, evidence capture, or certification.

Current upstream truth is `SESSION_NOT_VISIBLE`, `executionBlocked`,
`runnerInvoked = false`, and `structuredResultCaptured = false`, so Phase 135
truthfully publishes `Blocked`.

## Compatibility

The authority validates Phase 134 request compatibility, Phase 133 orchestration
compatibility, Phase 132 planning compatibility, Phase 131 readiness
compatibility, Phase 130 capability authority compatibility, Phase 129 protocol
metadata compatibility, request identifier consistency, execution intent validity,
exact schema closure, deterministic serialization, and immutable publication.

## Diagnostics

Diagnostics are tooling-only and expose dispatch version, dispatch state, request
state, execution intent, dispatch eligibility, validation state, compatibility
state, failure reason, and timestamp.

Diagnostics are not runtime evidence and cannot certify Chapter 0.

## Audit

Audit entries include dispatch id, request id, orchestration id, authority id,
dispatch state, dispatch eligibility, execution intent, timestamp, and contract
version. Audit history is append-only, immutable, deterministic, ordered, and
rejects duplicate identities.

## Integration Graph

Execution Dispatch Authority consumes the established authority chain:

`Evidence Transport -> Bridge -> Activation -> Binding -> Session -> Runner -> Integration Contract -> Capability Negotiation -> Execution Readiness -> Execution Planning -> Execution Orchestrator -> Execution Request -> Execution Dispatch`

No authority may be bypassed or replaced by dispatch publication.

## Current Result

No connected Studio MCP session identity is visible and execution remains blocked.
The authority publishes deterministic dispatch artifacts while preserving
`SESSION_NOT_VISIBLE`, `executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

Phase 135 is Production Candidate only. Phase 108 remains the latest Production
Certified milestone.

## Acceptance

Phase 135 is acceptable only when the dispatch authority exists, consumes Phase
134 requests read-only, validates and freezes deterministic dispatch artifacts,
derives eligibility truthfully from upstream state, preserves every upstream
authority boundary, introduces no execution capability, and keeps the repository
truthful about blocked Studio MCP execution.
