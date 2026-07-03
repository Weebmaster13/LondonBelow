# Schedule Plan Runtime

Schedule plans are descriptions, not commands.

Plan records describe future scheduling intent through schema ids for queues, slots, priorities, budgets, deadlines, retry policies, intervals, windows, dependencies, reason, metadata, context, and tags. They never enqueue, dispatch, run, retry, delay, or call work.

Plans reject invalid references, oversized reference lists, unsupported schedule kinds, unsafe payloads, and any execution-shaped fields.

## Hardening Rules

Plans reject live scheduling, task execution, RunService, queue processing, runtime orchestration, schedule execution, task handles, timer handles, coroutine handles, remotes, Workspace references, and service handles. A plan can describe future work shape only; it cannot dispatch, call, block, or run work.
