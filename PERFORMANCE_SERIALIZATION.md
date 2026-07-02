# Performance Serialization

Performance serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Diagnostics and snapshots are isolated copies. Serialization does not profile live systems, execute optimizations, throttle runtime behavior, collect analytics, send telemetry, or mutate runtime state.

Serialized records may describe future budgets, categories, thresholds, and reports, but they must not contain commands, callbacks, service references, remotes, profiler handles, optimization adapters, telemetry emitters, or runtime mutation instructions.

## Certified Serialization Posture

Budgets are policy data, not live measurements. Thresholds are warnings, not automatic throttles. Reports are schema records, not telemetry exports.

Serialization rejects any payload that attempts to smuggle execution or runtime authority through schema data, including profiler handles, optimizer adapters, throttling adapters, analytics emitters, telemetry exporters, remotes, client authority, Roblox Instances, callbacks, cyclic tables, oversized payloads, and deep payloads.

Future profilers, optimizers, throttlers, report exporters, and monitoring systems must be separate governed systems that read approved schema copies. They must not receive mutable references to Performance Budget Runtime state.
