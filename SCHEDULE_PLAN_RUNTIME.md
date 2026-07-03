# Schedule Plan Runtime

Schedule plans are descriptions, not commands.

Plan records describe future scheduling intent through schema ids for queues, slots, priorities, budgets, deadlines, retry policies, intervals, windows, dependencies, reason, metadata, context, and tags. They never enqueue, dispatch, run, retry, delay, or call work.

Plans reject invalid references, oversized reference lists, unsupported schedule kinds, unsafe payloads, and any execution-shaped fields.
