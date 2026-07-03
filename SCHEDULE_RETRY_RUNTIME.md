# Schedule Retry Runtime

Retries are policies, not retry execution.

Retry records describe no-retry, manual retry, fixed-gap retry, backoff-schema, bounded retry, or future retry policy data. They do not retry work, wait, schedule timers, or call task APIs.

Retries reject unsupported retry kinds, invalid attempt counts, unsafe payloads, and retry execution markers.
