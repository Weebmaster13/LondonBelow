# Execution Planning Runtime

Phase 148 creates the server-side Execution Planning Runtime under
`ServerScriptService/ExecutionPlanningRuntime/Core`.

The runtime describes what could execute, why it could execute, and which
conditions must remain true before later execution authorities may consider it.
It never executes anything.

## Ownership

Owns:

- deterministic execution planning graphs
- planning nodes
- planning dependencies
- planning constraints
- planning eligibility
- planning publication records
- planning diagnostics
- planning audit

Never owns:

- execution authorization
- scheduling
- Studio execution
- Runner invocation
- transport creation
- envelope transmission
- acknowledgement reception
- runtime evidence generation
- certification decisions
- gameplay or Workspace mutation

## Runtime Truth

Phase 148 preserves:

- `SESSION_NOT_VISIBLE`
- `executionBlocked = true`
- `runnerInvoked = false`
- `structuredResultCaptured = false`
- `transportCreated = false`
- `envelopeTransmitted = false`
- `acknowledgementReceived = false`

Planning publication is not execution evidence.

## Lifecycle

The legal lifecycle is one-way:

1. `UNINITIALIZED`
2. `BOOTSTRAPPING`
3. `GRAPH_BUILDING`
4. `DEPENDENCY_VALIDATION`
5. `CONSTRAINT_VALIDATION`
6. `ELIGIBILITY_ANALYSIS`
7. `PLAN_FINALIZATION`
8. `PLAN_PUBLICATION`
9. `COMPLETE`

Failures move to `FAILED` and do not publish a plan.

## Bootstrap

`ExecutionPlanningCoordinator` is registered by
`Core/Bootstrap.server.lua` after runtime scheduler registration and before
later graph/tooling modules. The local subsystem `Bootstrap.server.lua` is
intentionally inert so the runtime never auto-executes outside the governed
Core bootstrap path.
