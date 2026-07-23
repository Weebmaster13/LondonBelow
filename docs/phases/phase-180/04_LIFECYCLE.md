# Lifecycle

`RenderingExecutionLifecycle` exclusively owns execution state transitions.

Primary path:

`Created -> Queued -> Scheduled -> Executing -> WaitingAcknowledgement -> Acknowledged -> Completed -> Closed`

Terminal alternatives:

- `Cancelled`
- `Failed`
- `Expired`

Illegal transitions reject with `InvalidLifecycleTransition` and do not mutate session state. Cancellation and expiration preserve evidence and never delete execution history.
