# Runtime Scheduler Runtime Limits

Runtime Scheduler state is bounded by design.

Limits cover schedule plans, slots, queues, priorities, budgets, deadlines, retries, intervals, windows, dependencies, audits, validation failures, snapshots, payload depth, payload nodes, payload string length, tags per schema, plan queue refs, plan slot refs, plan budget refs, plan deadline refs, plan retry refs, plan interval refs, plan window refs, plan dependency refs, and audit findings.

Limit failures reject before state mutation. Hitting a limit does not evict source-of-truth schemas, run schedules, process queues, trigger retries, call timers, call RunService, mutate live runtime state, or execute anything.
