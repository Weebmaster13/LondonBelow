# Runtime Scheduler Runtime Limits

Runtime Scheduler state is bounded by design.

Limits cover schedule plans, slots, queues, priorities, budgets, deadlines, retries, intervals, windows, dependencies, audits, validation failures, snapshots, payload depth, payload nodes, payload string length, tags per schema, plan queue refs, plan slot refs, plan budget refs, plan deadline refs, plan retry refs, plan interval refs, plan window refs, plan dependency refs, and audit findings.

Limit failures reject before state mutation. Hitting a limit does not evict source-of-truth schemas, run schedules, process queues, trigger retries, call timers, call RunService, mutate live runtime state, or execute anything.

## Certified Limits

The runtime enforces every category limit and every plan reference list limit: schedule plans, slots, queues, priorities, budgets, deadlines, retries, intervals, windows, dependencies, audits, validation failures, snapshots, payload depth, payload nodes, string length, tags, plan queues, plan slots, plan budgets, plan deadlines, plan retries, plan intervals, plan windows, plan dependencies, and audit findings.

Limit failures do not dispatch tasks, process queues, start timers, trigger retry execution, call RunService, mutate runtime state, or evict already-accepted schemas.
