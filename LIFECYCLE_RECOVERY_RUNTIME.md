# Lifecycle Recovery Runtime

Recoveries are schemas, not recovery execution.

Recovery records describe no-recovery, manual review, retry later, restore previous schema, revalidate schema, disable schema, or future recovery policy data. They do not retry, restore, restart, disable, or mutate systems.

## Hardening Rules

Recoveries reject unsupported recovery kinds, invalid related failure references, retry execution, restart execution, restore execution, disable execution, lifecycle mutation, live service management, service lookup, callbacks, and execution adapters. A recovery record describes a future policy choice; it never performs recovery.
