# Waits, Timeouts, And Retries

Workflow waits may target events, query results, timeouts, or external approvals.

Timeouts are deterministic metadata records containing the wait state and timeout transition.

Retries are declarative metadata records containing reason, attempt, and maximum attempts. Retry records never mutate workflow definitions.

Suspension never blocks the runtime.
