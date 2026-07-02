# Analytics Serialization

Analytics serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Diagnostics and snapshots are isolated copies. Serialization is not analytics collection and does not send data anywhere.

## Safety Rules

- Serialization validates both table keys and values.
- Diagnostic copies sanitize unsafe runtime values instead of exposing raw references.
- Snapshot and diagnostics callers receive deep copies.
- Cyclic, Instance-like, function, thread, userdata, oversized, and overly deep payloads never become analytics boundary state.

Serialization is not telemetry. It only proves future analytics schemas can be represented safely before any collection, transport, reporting, or retention execution exists.
