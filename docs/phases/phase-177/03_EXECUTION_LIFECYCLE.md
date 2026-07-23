# Execution Lifecycle

`SessionExecutionEngine` owns execution session metadata.

`LifecycleExecutionEngine` validates every state transition before mutation. Illegal transitions reject safely and preserve unrelated executions.

Supported states include created, queued, assigned, preparing, executing, waiting for acknowledgement, acknowledged, completed, closed, cancelled, expired, failed, and suspended.
