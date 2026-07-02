# Tool Serialization

Developer Tooling serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Diagnostics and snapshots are isolated copies. Callers cannot mutate runtime state by editing returned tables.

## Safety Rules

- Serialization validates both table keys and values.
- Diagnostic copies sanitize unsafe runtime values instead of exposing raw references.
- Snapshot and diagnostics callers receive deep copies.
- Cyclic, Instance-like, function, thread, userdata, oversized, and overly deep payloads never become developer tooling state.

Serialization is not command execution. It only proves future tooling schemas can be safely represented before any separate execution or admin layer exists.
