# Asset Execution Boundary Review Serialization

Serialization is defensive and schema-only. Boundary review records are copied into isolated state after validation, and diagnostics/snapshots return isolated copies.

Serialization rejects cycles, Roblox Instances, instance-shaped tables, functions, threads, userdata, oversized strings, payloads deeper than the configured limit, and payloads with too many nodes.

Boundary review snapshots are evidence records, not executable state.
