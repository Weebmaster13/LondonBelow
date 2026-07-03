# Lifecycle Event Runtime

Events are schemas, not live EventBus emissions.

Event records describe future lifecycle event shapes and optional related state or transition ids. They do not publish gameplay events, emit runtime signals, or cause orchestration.

## Hardening Rules

Events reject unsupported event kinds, invalid related state references, invalid related transition references, live EventBus emission payloads, gameplay signal payloads, orchestration payloads, remotes, callbacks, and runtime object fields. They are schema records only; they never emit through EventBus.
