# Chapter 0 Home Phase 133 Studio Execution Orchestrator

Phase 133 creates `automation/studio-execution-orchestrator.mjs`, the sole
repository authority for Studio MCP execution orchestration.

This authority does not execute Studio, invoke the runner, simulate sessions,
capture runtime evidence, certify results, implement networking transport, write
persistence, render content, or mutate gameplay. It consumes the Phase 132
execution plan and publishes an immutable orchestration model.

## Ownership

The authority owns orchestration lifecycle, sequencing, graph construction,
orchestration stages, checkpoint references, state publication, metadata,
diagnostics, audit, cancellation metadata, and retry metadata.

It does not own Studio execution, runner execution, readiness evaluation,
execution planning, capability negotiation, protocol definition, certification,
gameplay, networking, persistence, rendering, or runtime evidence.

## Lifecycle

Success path:

`Idle -> CollectExecutionPlan -> ValidateExecutionPlan -> BuildOrchestrationGraph -> FreezeOrchestration -> OrchestrationReady`

Failure paths:

- `CollectExecutionPlan -> MissingExecutionPlan`
- `ValidateExecutionPlan -> ExecutionPlanRejected`
- `BuildOrchestrationGraph -> OrchestrationFailure`
- `FreezeOrchestration -> FreezeRejected`

Illegal, skipped, cyclic, and terminal-mutating transitions reject.

## Orchestration Graph

The orchestration graph contains graph id, graph version, orchestration stages,
dependency edges, checkpoint references, ordered stages, and validation state. It
never invokes execution.

Graph validation verifies stage completeness, duplicate stage rejection,
dependency ordering, dependency completeness, graph closure, unreachable stage
rejection, cyclic dependency rejection, and checkpoint reference uniqueness.

## Orchestration Stages

Supported orchestration stages are:

- `AcquirePlan`
- `ValidateAuthorities`
- `ValidateReadiness`
- `ValidatePlanning`
- `FreezeExecutionContext`
- `AwaitExecutionAuthority`

These stages are orchestration concepts only. They never launch Studio, invoke
the runner, open transport, capture evidence, or mutate gameplay.

## Execution Context

The frozen execution context contains context id, protocol version, readiness id,
execution plan id, capability profile id, graph id, validation state, and
timestamp. It is immutable after publication.

## Retry Policy

Retry policy metadata is deterministic and contains retry policy id,
classification, eligibility, retry window, and reason. Retry policy metadata never
executes retries.

## Cancellation Policy

Cancellation policy metadata supports `NotRequested`, `CancellationPending`,
`CancellationAccepted`, and `CancellationRejected`. Cancellation metadata never
affects runtime execution.

## Diagnostics And Audit

Diagnostics are tooling-only and expose orchestration version, graph state,
readiness state, planning state, orchestration state, retry state, cancellation
state, validation state, failure reason, and timestamp.

Audit entries include orchestration id, graph id, context id, authority id, state,
retry state, cancellation state, timestamp, and contract version. Audit history is
append-only, immutable, deterministic, ordered, and rejects duplicate identities.

## Integration Graph

Execution Orchestrator consumes the established authority chain:

`Evidence Transport -> Bridge -> Activation -> Binding -> Session -> Runner -> Integration Contract -> Capability Negotiation -> Execution Readiness -> Execution Planning -> Execution Orchestrator`

No authority may be bypassed or replaced by orchestration.

## Current Result

No connected Studio MCP session identity is visible and execution remains blocked.
The orchestrator publishes deterministic orchestration artifacts while preserving
`SESSION_NOT_VISIBLE`, `executionBlocked`, `runnerInvoked = false`, and
`structuredResultCaptured = false`.

Phase 133 is Production Candidate only. Phase 108 remains the latest Production
Certified milestone.
