# Execution Serialization

`ExecutionSerialization` is the safety boundary for request data, diagnostics, and snapshots.

## Rejected Values

- Roblox Instances
- functions
- threads
- userdata
- cyclic tables
- oversized strings
- oversized node counts
- overly deep payloads

## Diagnostics Safety

Diagnostics use sanitized copies. Unsafe runtime values become markers such as `<RobloxInstance>`, `<unsafe:function>`, `<cycle>`, or `<max-depth>`.

## Snapshot Safety

Snapshots are deep-copied. Modifying a returned snapshot must not mutate bridge runtime state.
