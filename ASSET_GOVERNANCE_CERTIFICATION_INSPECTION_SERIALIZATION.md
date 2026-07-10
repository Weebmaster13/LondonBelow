# Asset Governance Certification Inspection Serialization

Serialization performs bounded deep-copy and diagnostic-copy operations for copied inspection metadata.

Serializable payloads may contain strings, numbers, booleans, nil values, and plain tables within configured limits. Serialization rejects functions, threads, userdata, Instance-shaped tables, cycles, oversized strings, oversized node counts, deep payloads, runtime handles, callbacks, module references, execution adapters, repair markers, authorization markers, mutation markers, scheduling markers, and orchestration markers.

Diagnostics use sanitized copies so unsafe rejected payloads do not leak mutable or executable values.
