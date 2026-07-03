# Schedule Deadline Runtime

Deadlines are metadata, not timers.

Deadline records describe soft, hard, expiration, review, or future deadline policy data. They do not create timers, expire work, or execute timeout behavior.

Deadlines reject unsupported deadline kinds, unsafe payloads, and timeout execution markers.

## Hardening Rules

Deadlines reject timer execution, timeout execution, task.delay markers, live time checks, task handles, timer handles, callbacks, and execution adapters. Deadlines are metadata only; they never start timers or expire work.
