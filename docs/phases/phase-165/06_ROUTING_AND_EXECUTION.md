# Routing and Execution

`CommandRouter.lua` produces a deterministic single-handler execution plan.

`CommandQueue.lua` provides bounded priority queueing with Critical, High, Normal, and Low priority order plus FIFO within equal priority.

`CommandExecutionRuntime.lua` executes the resolved authoritative handler and records normalized success or failure results.

The legal lifecycle is `Created -> Submitted -> Validated -> Authorized -> Queued -> Scheduled -> Executing -> Completed`, with `Rejected`, `Cancelled`, and `Failed` as terminal states. Illegal transitions are rejected. Handler resolution occurs before queue admission so no accepted command enters the runtime queue without exactly one authoritative execution path.
