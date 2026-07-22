# Routing and Execution

`CommandRouter.lua` produces a deterministic single-handler execution plan.

`CommandQueue.lua` provides bounded priority queueing with Critical, High, Normal, and Low priority order plus FIFO within equal priority.

`CommandExecutionRuntime.lua` executes the resolved authoritative handler and records normalized success or failure results.

The legal lifecycle is `Created -> Submitted -> Validated -> Authorized -> Queued -> Scheduled -> Executing -> Completed`, with `Rejected`, `Cancelled`, and `Failed` as terminal states. Illegal transitions are rejected. Handler resolution occurs before queue admission so no accepted command enters the runtime queue without exactly one authoritative execution path.

Part III hardening adds execution policy metadata and deterministic execution safety modules:

- `CommandExecutionPolicy.lua` normalizes Immediate, Deferred, Scheduled, Exclusive, Transactional, and Batch policy metadata.
- `CommandLockManager.lua` acquires sorted bounded lock ids before execution and releases all held locks after dispatch or shutdown.
- `CommandTransactionRuntime.lua` coordinates transaction metadata through creation, commit, and rollback without implementing gameplay recovery.
- `CommandRetryRuntime.lua` evaluates NeverRetry, RetryOnce, and BoundedRetry using engine-attempt counts instead of wall time.
- `CommandReplay.lua` records replay metadata from command sequence, priority, authority, and policy.
- `CommandRecovery.lua` records interrupted execution state for owner-runtime recovery decisions.
- `CommandBatchRuntime.lua` records batch metadata while preserving independent command envelopes.
- `CommandAncestry.lua` records correlation/causation ancestry and rejects circular or over-depth nesting.

The bus still resolves exactly one handler and one authoritative owner. Part III does not add gameplay execution, remotes, persistence writes, rendering, client authority, or domain rollback logic.
