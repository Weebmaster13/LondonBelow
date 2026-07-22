# Routing and Execution

`CommandRouter.lua` produces a deterministic single-handler execution plan.

`CommandQueue.lua` provides bounded priority queueing with Critical, High, Normal, and Low priority order plus FIFO within equal priority.

`CommandExecutionRuntime.lua` executes the resolved authoritative handler and records normalized success or failure results.
