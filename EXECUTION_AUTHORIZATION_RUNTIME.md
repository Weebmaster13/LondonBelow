# Execution Authorization Runtime

Phase 149 creates the server-side Execution Authorization Runtime under
`ServerScriptService/ExecutionAuthorizationRuntime/Core`.

The runtime evaluates whether a published execution plan would be authorized for
future execution consideration if execution ever becomes legal. It does not
execute, schedule, invoke Studio, invoke the Runner, create transport, transmit
envelopes, receive acknowledgements, generate runtime evidence, or certify.

## Ownership

Owns:

- authorization policies
- authorization rules
- authorization evaluation
- authorization decisions
- authorization publication
- authorization diagnostics
- authorization audit
- authorization snapshots
- authorization validation
- authorization self-checks

Never owns:

- execution planning
- execution scheduling
- Studio execution
- Runner invocation
- transport creation
- runtime evidence
- gameplay mutation
- persistence
- analytics
- telemetry
- certification

## Inputs

The runtime consumes Phase 148 planning publications read-only:

- published execution plans
- planning version
- planning classification
- dependency summaries
- constraint summaries
- eligibility summaries
- blocked runtime truth

It never mutates planning publications.

## Runtime Truth

Phase 149 preserves:

- `SESSION_NOT_VISIBLE`
- `executionBlocked = true`
- `runnerInvoked = false`
- `structuredResultCaptured = false`
- `transportCreated = false`
- `envelopeTransmitted = false`
- `acknowledgementReceived = false`

An authorization decision is metadata only. `AUTHORIZED` never means execution
permission exists.

## Bootstrap

`ExecutionAuthorizationCoordinator` registers after
`ExecutionPlanningCoordinator` in `Core/Bootstrap.server.lua`.
