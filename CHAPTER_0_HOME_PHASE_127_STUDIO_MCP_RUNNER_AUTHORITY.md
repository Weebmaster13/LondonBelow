# Chapter 0 Home Phase 127 Studio MCP Runner Authority Foundation

Phase 127 establishes the repository Runner Authority for future Studio MCP runner
orchestration. It is infrastructure only. It does not execute Studio, invoke
`Phase118CertificationRunner`, certify gameplay, synthesize runtime evidence, or
modify Chapter 0 gameplay behavior.

## Authority

`automation/studio-runner-authority.mjs` is the sole owner of runner lifecycle
orchestration. It owns request creation, immutable request identity, execution
identity, lifecycle state, timeout classification, cancellation classification,
retry classification, diagnostics, timestamps, audit trail, and bridge-facing
execution posture.

It does not own Studio execution, connected-session discovery, runner-binding
discovery, MCP activation, evidence validation, certification, gameplay,
networking, persistence, analytics, telemetry, rendering, save runtime, remotes, or
Chapter content.

## Ownership Matrix

| Surface | Owner |
| --- | --- |
| Certification decision | `Phase118CertificationContract` |
| Evidence transport | Phase 121 capture tooling |
| Studio discovery and bridge posture | Phase 122 bridge |
| Structured capture envelope | Phase 123 bridge validation |
| MCP activation prerequisites | Phase 124 activation authority |
| Runner command binding | Phase 125 binding authority |
| Connected session identity | Phase 126 session authority |
| Runner lifecycle orchestration | Phase 127 Runner Authority |

## Execution Lifecycle

Allowed lifecycle states:

```text
Created -> Queued -> WaitingForSession -> Ready -> Executing -> Completed
Created -> Rejected
WaitingForSession -> Blocked
Executing -> TimedOut
Executing -> Cancelled
Executing -> Failed
Executing -> Disconnected
```

Allowed status values:

```text
created
queued
waiting
ready
executing
completed
blocked
cancelled
timedOut
failed
disconnected
unknown
```

No undocumented lifecycle or status value is accepted.

## Request Contract

Every request contains exactly:

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

Request identity is immutable once created.

## Preconditions

The authority may not transition to `Ready` unless all upstream authorities pass:

- Phase 126 session authority reports `connected`;
- Phase 125 binding authority reports `bindingReady`;
- Phase 124 activation authority reports `activationReady`;
- repository validation passes;
- source attribution is valid;
- working tree is clean;
- local `HEAD` matches `origin/main`.

If any prerequisite fails, the authority remains `blocked` and runner execution is
not attempted.

## Timeout Model

Timeout classification is owned by the Runner Authority:

- `NoTimeout`
- `WaitingTimeout`
- `ExecutionTimeout`
- `HeartbeatTimeout`
- `CancellationTimeout`

## Retry Policy

Retry ownership is local to the Runner Authority. Retryable reasons are limited to:

- `Reconnect`
- `TemporaryBridgeFailure`
- `TemporarySessionFailure`
- `RepositoryRestart`

Validation failures, certification failures, unsupported bindings, missing
sessions, and unknown protocols are never retried automatically.

## Cancellation Policy

Cancellation is terminal. Cancellation reasons are:

- `UserCancelled`
- `RepositoryShutdown`
- `BridgeFailure`
- `SessionDisconnected`
- `ValidationFailure`
- `AuthorityConflict`
- `Timeout`
- `Unknown`

## Diagnostics

Diagnostics include request id, runner id, authority id, execution state, session
state, binding state, activation state, repository state, bridge state, retry
state, timeout state, failure reason, recommended action, timestamps, transitions,
and audit trail.

## Current Result

No connected Studio MCP session identity is visible. The Runner Authority reports
`blocked`, keeps `runnerInvoked` false, keeps `structuredResultCaptured` false, and
preserves `executionBlocked`.

## Acceptance Criteria

Phase 127 is accepted only when the Runner Authority self-checks pass, existing
bridge/session/binding/wrapper validation remains passing, source validation passes,
forbidden scans are clean, and no Production Certification is claimed.
