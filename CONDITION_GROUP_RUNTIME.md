# Condition Group Runtime

Condition groups describe logical structure only. Supported group types are AND, OR, NOT, Exclusive, and FutureGroup.

Groups do not evaluate child conditions, short-circuit logic, fire triggers, gate gameplay, or complete objectives. They only preserve a stable future relationship between registered condition definitions.

Group validation requires registered condition ids and bounded group size.

## Production Hardening

Groups reject unsupported schema types, unsupported group types, invalid condition references, oversized condition lists, branching execution markers, short-circuit markers, unsafe payloads, callbacks, runtime objects, remotes, client markers, Workspace markers, and Chapter content. Groups never branch live gameplay.
