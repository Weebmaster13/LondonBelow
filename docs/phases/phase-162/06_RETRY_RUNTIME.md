# Retry Runtime

Retry modes are `Immediate`, `LimitedRetry`, and `PermanentFailure`.

Retries are bounded by `Types.Limits.MaxRetryAttempts`. Infinite retries are not allowed. Retry attempts are recorded as bounded evidence and diagnostics only.
