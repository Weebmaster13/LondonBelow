# Asset Execution Permit Serialization

Serialization is defensive and schema-only. Permit records are copied into isolated state after validation, and diagnostics/snapshots return isolated copies.

Serialization rejects cycles, Roblox Instances, instance-shaped tables, functions, threads, userdata, oversized strings, payloads deeper than the configured limit, and payloads with too many nodes.

Permit snapshots are evidence records, not executable state.
