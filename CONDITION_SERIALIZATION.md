# Condition Serialization

Condition serialization is defensive and schema-only. It deep copies accepted records and rejects unsafe runtime values, cycles, oversized payloads, oversized strings, and excessive depth.

Diagnostics use sanitized copies so unsafe payloads cannot leak executable values. Snapshots use isolated deep copies so callers cannot mutate runtime state by changing returned tables.

Serialization does not persist, load, migrate, transmit, evaluate, or execute condition schemas.
