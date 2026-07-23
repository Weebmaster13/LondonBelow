# Scheduler And Queue

`RenderingExecutionQueue` owns queue admission, deterministic ordering, suspension, and resumption. Ordering is by runtime priority, assignment priority, queue ordinal, and stable execution session id. Wall-clock timing is not used for authority.

`RenderingExecutionScheduler` is the sole dispatch authority. It transitions queued sessions to scheduled state, assigns execution workload metadata, executes scheduled sessions, records evidence, and exposes scheduler posture for diagnostics.

The scheduler supports `Idle`, `Scheduling`, `Executing`, `Suspended`, `Recovering`, and `Shutdown` metadata states. Shutdown blocks future scheduling safely.
