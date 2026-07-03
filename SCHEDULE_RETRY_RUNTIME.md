# Schedule Retry Runtime

Retries are policies, not retry execution.

Retry records describe no-retry, manual retry, fixed-gap retry, backoff-schema, bounded retry, or future retry policy data. They do not retry work, wait, schedule timers, or call task APIs.

Retries reject unsupported retry kinds, invalid attempt counts, unsafe payloads, and retry execution markers.

## Hardening Rules

Retries reject retry execution, task.delay markers, coroutine markers, task handles, timer handles, coroutine handles, callbacks, and execution adapters. Retry records describe policy only; they never retry or wait.
