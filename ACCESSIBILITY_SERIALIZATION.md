# Accessibility Serialization

Accessibility serialization deep-copies public exports and sanitizes diagnostics payloads.

It rejects Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized node counts, and overly deep payloads.

Diagnostics and snapshots are isolated copies. Serialization does not execute accessibility settings.

## Certified Serialization Posture

Accessibility serialization is defensive before it is convenient. It rejects cyclic payloads, Roblox Instances, unsafe runtime values, oversized strings, oversized node counts, and excessive nesting before any schema reaches runtime state.

All registered schemas are stored through deep copies. All diagnostics and snapshots are exported through deep copies or diagnostic-safe copies. Future accessibility presentation systems must never receive mutable references to server-owned schema state.

Serialization is also part of the no-execution boundary. Serialized records may describe future settings, safety policies, and constraints, but they must not contain commands, callbacks, Instances, service references, execution adapters, remotes, final UI definitions, or sensory effect instructions.
