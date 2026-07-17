# Chapter 0 Home Phase 134 Studio Execution Request Authority

Phase 134 creates `automation/studio-execution-request-authority.mjs`, the sole
repository authority for Studio MCP execution requests.

This authority does not execute Studio, invoke the runner, simulate sessions,
capture runtime evidence, certify results, implement networking transport, write
persistence, render content, or mutate gameplay. It consumes the Phase 133
execution orchestrator read-only and publishes an immutable execution request
that a future execution runtime could consume.

## Ownership

The authority owns execution request construction, request identity, exact request
schema, request lifecycle validation, request publication, request metadata,
diagnostics, audit, and compatibility checks.

It does not own Studio execution, orchestration, execution planning, readiness
evaluation, capability negotiation, protocol definition, certification, gameplay,
networking, persistence, rendering, or runtime evidence.

## Lifecycle

Success path:

`Idle -> CreateRequest -> ValidateRequest -> FreezeRequest -> RequestPublished`

Failure paths:

- `CreateRequest -> InvalidInput`
- `ValidateRequest -> RequestRejected`
- `FreezeRequest -> FreezeRejected`

Illegal, skipped, cyclic, and terminal-mutating transitions reject.

## Execution Request Schema

Every execution request contains exactly:

- `requestId`
- `orchestrationId`
- `executionPlanId`
- `readinessId`
- `protocolVersion`
- `capabilityProfileId`
- `requestVersion`
- `executionIntent`
- `validationState`
- `timestamp`

Unknown fields reject. Duplicate identities reject. Requests are frozen before
publication.

## Execution Intent

Supported intent values are:

- `ValidationOnly`
- `DryRun`
- `AuthoritativeExecution`

These values are classifications only. No intent triggers Studio execution,
runner invocation, structured capture, gameplay mutation, or certification.

## Compatibility

The authority validates schema completeness, identifier uniqueness, protocol
compatibility, orchestration compatibility, readiness compatibility, capability
compatibility, deterministic serialization, and immutable publication.

Requests failing validation are never published.

## Diagnostics

Diagnostics are tooling-only and expose request version, request state, intent,
validation state, compatibility state, failure reason, and timestamp.

Diagnostics do not include certification decisions, runtime evidence, or gameplay
state.

## Audit

Audit entries include request id, orchestration id, authority id, request state,
intent, timestamp, and contract version. Audit history is append-only,
immutable, deterministic, ordered, and rejects duplicate identities.

## Integration Graph

Execution Request Authority consumes the established authority chain:

`Evidence Transport -> Bridge -> Activation -> Binding -> Session -> Runner -> Integration Contract -> Capability Negotiation -> Execution Readiness -> Execution Planning -> Execution Orchestrator -> Execution Request`

No authority may be bypassed or replaced by request publication.

## Current Result

No connected Studio MCP session identity is visible and execution remains blocked.
The authority publishes deterministic request artifacts while preserving
`SESSION_NOT_VISIBLE`, `executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

Phase 134 is Production Candidate only. Phase 108 remains the latest Production
Certified milestone.

## Acceptance

Phase 134 is acceptable only when the request authority exists, validates and
freezes deterministic requests before publication, preserves every upstream
authority boundary, introduces no execution capability, and keeps the repository
truthful about blocked Studio MCP execution.
