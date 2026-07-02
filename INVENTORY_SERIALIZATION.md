# Inventory Serialization

Inventory serialization provides defensive deep-copying and sanitization for schema payloads.

It rejects:

- Roblox Instances
- functions
- threads
- userdata
- cyclic tables
- oversized strings
- excessive table depth
- excessive node counts

Snapshots and diagnostics use isolated copies so external callers cannot mutate runtime state through returned tables.
