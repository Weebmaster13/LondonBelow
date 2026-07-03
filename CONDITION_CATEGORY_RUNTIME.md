# Condition Category Runtime

Condition categories classify condition schemas by domain and intent. They are taxonomy records, not execution domains and not branching logic.

Categories may help future systems organize condition definitions for readability, diagnostics, or tooling. They do not grant authority, evaluate conditions, dispatch rules, or mutate state.

Category payloads must remain serializable, bounded, server-owned, and free of client, remote, service, Workspace, Chapter, story, dialogue, cutscene, analytics, telemetry, or execution fields.

## Production Hardening

Categories reject unsupported schema types, unsupported domains, unsafe metadata/context/tags, execution-domain markers, remote markers, client markers, service markers, analytics markers, telemetry markers, and Chapter content. Categories are taxonomy only.
