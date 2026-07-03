# TRIGGER SERIALIZATION

Trigger serialization deep copies accepted schema records and rejects unsafe runtime values, cycles, oversized strings, oversized node counts, and excessive depth. Diagnostics are sanitized and snapshots are isolated.

