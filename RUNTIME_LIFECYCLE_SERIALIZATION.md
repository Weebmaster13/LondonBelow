# Runtime Lifecycle Serialization

Runtime Lifecycle serialization protects schema state, diagnostics, and snapshots.

Authoritative records reject Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized node counts, and deep payloads. Diagnostic copies sanitize unsafe values, service references, remote references, runtime objects, callbacks, module references, Framework references, Workspace paths, live lifecycle markers, live service handles, and execution adapters.

Snapshots, diagnostics, and public exports are isolated deep copies.
