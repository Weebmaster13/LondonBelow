# ExecutionAudit Schema

`ExecutionAudit` records copied audit metadata for execution runtime records.

It requires an existing `ExecutionRuntime` parent and validates request and boundary references against that same runtime.

It is review metadata only and does not approve, reject, route, dispatch, schedule, orchestrate, or execute work.
