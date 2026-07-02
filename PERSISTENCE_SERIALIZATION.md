# Persistence Serialization

Persistence serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads. Diagnostics and snapshots are isolated copies.

## Safety Rules

- Serialization validates both keys and values.
- Diagnostic copies sanitize unsafe runtime values instead of exposing raw references.
- Snapshot and diagnostics callers receive deep copies.
- Cyclic, Instance-like, function, thread, userdata, oversized, and overly deep payloads never become persistence boundary state.

Serialization is not persistence. It only proves future persistence packages can be safely represented before a separate DataStore execution layer exists.
