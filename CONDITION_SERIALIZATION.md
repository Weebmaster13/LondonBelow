# Condition Serialization

Condition serialization is defensive and schema-only. It deep copies accepted records and rejects unsafe runtime values, cycles, oversized payloads, oversized strings, and excessive depth.

Diagnostics use sanitized copies so unsafe payloads cannot leak executable values. Snapshots use isolated deep copies so callers cannot mutate runtime state by changing returned tables.

Serialization does not persist, load, migrate, transmit, evaluate, or execute condition schemas.

## Production Hardening

Serialization validates table keys and values, rejects cycles, rejects unsafe runtime values, rejects oversized strings, rejects oversized node counts, rejects deep payloads, sanitizes diagnostics payloads, and ensures public snapshots and diagnostics cannot expose mutable source-of-truth tables.
