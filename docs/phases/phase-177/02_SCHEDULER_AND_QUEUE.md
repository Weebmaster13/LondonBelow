# Scheduler And Queue

`PresentationExecutionScheduler` owns one scheduler state at a time.

`PresentationExecutionQueue` owns waiting, assigned, executing, suspended, cancelled, and expired execution ids.

Ordering is deterministic by runtime priority, queue ordinal, execution ordinal, and stable identifier. Wall-clock time is not ordering authority.
