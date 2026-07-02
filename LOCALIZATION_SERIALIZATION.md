# Localization Serialization

Localization serialization deep-copies public exports and sanitizes diagnostics payloads.

It validates table keys and values, rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Snapshots and diagnostics are isolated copies. They must not contain final story text, final dialogue text, service references, executable callbacks, external translation handles, or remote references.
