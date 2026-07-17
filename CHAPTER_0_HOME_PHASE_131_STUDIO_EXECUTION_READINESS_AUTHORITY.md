# Chapter 0 Home Phase 131 Studio Execution Readiness Authority

Phase 131 creates `automation/studio-execution-readiness-authority.mjs`, the sole
repository authority for execution readiness decisions.

This authority does not execute Studio, invoke the runner, capture evidence,
certify results, implement networking transport, simulate sessions, write
persistence, or mutate gameplay. It aggregates read-only upstream authority
posture into one deterministic readiness decision.

## Ownership

The authority owns readiness evaluation, prerequisite aggregation, readiness
rules, readiness decision publication, diagnostics, audit, lifecycle, readiness
profiles, and readiness compatibility validation.

It does not own protocol definition, capability negotiation, runner lifecycle,
session discovery, Studio execution, networking transport, gameplay, persistence,
rendering, runtime evidence, or certification.

## Lifecycle

Success path:

`Idle -> CollectAuthorities -> EvaluatePrerequisites -> FreezeDecision -> ExecutionReady`

Failure paths:

- `CollectAuthorities -> MissingAuthority`
- `EvaluatePrerequisites -> ExecutionBlocked`
- `FreezeDecision -> FreezeRejected`

Illegal, skipped, cyclic, and terminal-mutating transitions reject.

## Prerequisites

Readiness evaluates protocol compatibility, negotiated capability profile,
activation readiness, binding readiness, connected session, runner readiness,
repository validation, source attribution, version compatibility, and authority
integrity. No prerequisite is inferred.

## Decision

The authority publishes exactly one decision:

- `ExecutionReady`
- `ExecutionBlocked`
- `ReadinessUnknown`

`ExecutionReady` requires every prerequisite to pass. Otherwise the published
decision remains `ExecutionBlocked`.

## Readiness Profile

Profiles are immutable and contain readiness id, evaluation id, protocol state,
capability state, activation state, binding state, session state, runner state,
repository state, validation state, decision, and timestamp.

## Blocking Reasons

Supported blocking reasons are `MissingSession`, `ActivationBlocked`,
`BindingBlocked`, `RunnerBlocked`, `CapabilityMissing`, `ProtocolRejected`,
`RepositoryInvalid`, `ValidationFailed`, `SourceInvalid`,
`CompatibilityFailure`, and `Unknown`.

## Diagnostics And Audit

Diagnostics are tooling-only and expose readiness version, decision, blocking
reasons, blocking authorities, upstream states, repository state, validation state,
and timestamp.

Audit entries include evaluation id, authority id, decision, blocking reasons,
profile id, timestamp, and contract version. Audit history is immutable,
deterministic, ordered, and rejects duplicate identities.

## Current Result

No connected Studio MCP session identity is visible and upstream authorities are
not ready. The repository continues to report `SESSION_NOT_VISIBLE`,
`executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

Phase 131 is Production Candidate only. Phase 108 remains the latest Production
Certified milestone.
