# Schedule Queue Runtime

Queues are classification records, not live queues.

Queue records describe future categories such as runtime, diagnostic, snapshot, validation, presentation, gameplay, persistence, tooling, or future queues. They do not hold live work, process items, dispatch jobs, or own queue state.

Queues reject unsupported queue kinds, invalid priority or budget references, unsafe payloads, and queue-processing markers.

## Hardening Rules

Queues reject live queue objects, dispatch state, queue processing, dispatch execution, task execution, callbacks, execution adapters, remotes, and runtime object markers. A queue classifies future work; it never stores or processes live work.
