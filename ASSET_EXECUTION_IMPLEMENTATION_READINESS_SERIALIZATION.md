# Asset Execution Implementation Readiness Serialization

Serialization is defensive and schema-only. implementation readiness records are copied into isolated state after validation, and diagnostics/snapshots return isolated copies.

Serialization rejects cycles, Roblox Instances, instance-shaped tables, functions, threads, userdata, oversized strings, payloads deeper than the configured limit, and payloads with too many nodes.

implementation readiness snapshots are evidence records, not executable state.
