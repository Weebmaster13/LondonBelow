# Asset Readiness Review Serialization

Serialization is defensive and schema-only. Runtime values are rejected before registration, and diagnostic copies sanitize unsafe values instead of leaking handles.

Serialization rejects cycles, Roblox Instances, instance-shaped tables, functions, threads, userdata, oversized strings, payloads deeper than the configured limit, and payloads with too many nodes.

Snapshots and diagnostics return isolated deep copies. Future execution runtimes must not receive mutable references from this boundary.
