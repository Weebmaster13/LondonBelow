# TRIGGER GROUP RUNTIME

Trigger groups are structural records only. Sequential, Parallel, Exclusive, Priority, and FutureGroup describe future organization, not live batching or orchestration.

## Production Hardening

Production hardening: groups reject unsupported schema types, unsupported group types, invalid trigger references, oversized member lists, unsafe payloads, execution batch markers, orchestration markers, callbacks, services, remotes, and Workspace references.
