# Chapter 0 Home Phase 128 Studio MCP Runner Authority Production Hardening

Phase 128 freezes the Runner Authority public contract without adding execution
capability. It remains automation infrastructure only and does not execute Studio,
simulate MCP sessions, invoke `Phase118CertificationRunner`, validate
certification evidence, certify gameplay, or generate runtime evidence.

## Contract

The Runner Authority contract is versioned by:

```text
contractVersion: 1.0.0
authorityVersion: phase128.productionHardening
schemaVersion: 1
```

Unsupported contract versions reject before orchestration. Future phases may add a
new version, but they must not silently alter version `1.0.0`.

## Compatibility Guarantees

- Request identity is immutable.
- Execution identity is immutable.
- Audit entries are immutable.
- Diagnostics fields are closed.
- Request fields are closed.
- Lifecycle transitions are closed.
- Terminal states are immutable.
- Timeout, retry, and cancellation ownership remains in Runner Authority.
- Certification remains owned by `Phase118CertificationContract`.

## Request Schema

Every request contains exactly:

- `contractVersion`
- `requestId`
- `phase`
- `authority`
- `requestedRunner`
- `repositoryCommit`
- `sourceAttribution`
- `bindingState`
- `sessionState`
- `validationState`
- `requestedAt`
- `expiresAt`

Unknown fields, missing fields, invalid version, invalid authority, invalid runner,
invalid status, invalid session state, or invalid timestamps reject.

## Lifecycle Contract

Legal transitions are:

```text
Created -> Queued
Created -> Rejected
Queued -> WaitingForSession
WaitingForSession -> Ready
WaitingForSession -> Blocked
WaitingForSession -> TimedOut
WaitingForSession -> Cancelled
Ready -> Executing
Ready -> Cancelled
Executing -> Completed
Executing -> TimedOut
Executing -> Cancelled
Executing -> Failed
Executing -> Disconnected
```

Undocumented, skipped, cyclic, duplicate terminal, and terminal-to-any transitions
reject.

## Timeout Policy

Timeout classifications remain:

- `NoTimeout`
- `WaitingTimeout`
- `ExecutionTimeout`
- `HeartbeatTimeout`
- `CancellationTimeout`

Bridge, Session, Activation, and Binding authorities do not own runner timeouts.

## Retry Policy

Allowed retry classifications remain:

- `Reconnect`
- `TemporaryBridgeFailure`
- `TemporarySessionFailure`
- `RepositoryRestart`

Validation failures, certification failures, unsupported bindings, missing session
identity, and unknown protocol are non-retryable.

## Cancellation Policy

Cancellation is terminal. Duplicate cancellation, cancellation after completion,
cancellation after timeout, and cancellation loops reject through lifecycle
validation.

## Diagnostics Contract

Diagnostics expose exactly:

- `contractVersion`
- `authorityVersion`
- `requestIdentity`
- `executionIdentity`
- `lifecycleState`
- `timeoutClassification`
- `retryClassification`
- `sessionState`
- `bindingState`
- `activationState`
- `bridgeState`
- `validationState`
- `timestamps`
- `auditReference`

No undocumented diagnostics fields are accepted.

## Audit Contract

Audit entries preserve insertion order, request id, execution id, state, reason,
timestamp, and authority id. Audit validation rejects mutation, deletion,
duplication, identity mismatch, authority mismatch, timestamp drift, and entries
after a terminal state.

## Integration Boundaries

Runner Authority consumes Phase 126 Session Authority, Phase 125 Binding
Authority, Phase 124 Activation Authority, Phase 122 Bridge posture, Phase 121
Evidence Transport posture, and Phase 118 certification identity. It does not
replace or duplicate any of those authorities.

## Current Result

No connected Studio MCP session identity is visible. The authority reports
`blocked`, `executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

## Acceptance Criteria

Phase 128 is accepted when contract self-checks pass, all repository validation
passes, forbidden scans are clean, origin/main is verified, and Phase 108 remains
the latest Production Certified milestone.
