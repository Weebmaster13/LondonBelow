# Performance Serialization

Performance serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Diagnostics and snapshots are isolated copies. Serialization does not profile live systems, execute optimizations, throttle runtime behavior, collect analytics, send telemetry, or mutate runtime state.

Serialized records may describe future budgets, categories, thresholds, and reports, but they must not contain commands, callbacks, service references, remotes, profiler handles, optimization adapters, telemetry emitters, or runtime mutation instructions.
