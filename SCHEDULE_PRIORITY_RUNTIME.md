# Schedule Priority Runtime

Priorities are policy values, not dispatch commands.

Priority records describe future priority meaning and optional numeric priority values. They do not sort live work, dispatch tasks, or preempt runtime systems.

Priorities reject unsupported priority kinds, invalid values, unsafe payloads, and dispatch markers.

## Hardening Rules

Priorities reject dispatch execution, task execution, runtime API calls, callbacks, and execution adapters. A priority value can guide future policy review only; it cannot dispatch or preempt work.
