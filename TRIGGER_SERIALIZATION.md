# TRIGGER SERIALIZATION

Trigger serialization deep copies accepted schema records and rejects unsafe runtime values, cycles, oversized strings, oversized node counts, and excessive depth. Diagnostics are sanitized and snapshots are isolated.

## Production Hardening

Production hardening: serialization validates keys and values, rejects Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized node counts, and deep payloads. Diagnostic copies sanitize unsafe values and public exports do not expose mutable state.
