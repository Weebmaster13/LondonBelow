# Physical Serialization

`PhysicalSerialization` deep-copies public state and rejects unsafe runtime values.

## Rejected Values

- Roblox Instances
- functions
- threads
- userdata
- cyclic tables
- oversized payloads
- oversized strings
- deep payloads

## Diagnostics Safety

Diagnostics sanitize unsafe values before storing validation failures. Unsafe values become markers such as `<RobloxInstance>`, `<unsafe:function>`, `<cycle>`, or `<max-depth>`.

## Snapshot Safety

Snapshots are isolated deep copies. Mutating a returned snapshot must not mutate runtime state.

## Diagnostics Safety

Rejected unsafe payloads are sanitized before diagnostics store them. Diagnostics must never retain direct Roblox Instances, functions, threads, userdata, cyclic references, or oversized raw strings.
