# World Serialization

World serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads. Diagnostics and snapshots are isolated copies so callers cannot mutate runtime state through returned tables.

Diagnostic copies sanitize unsafe values instead of returning live runtime objects. Snapshot exports use deep copies and preserve schema data only.
