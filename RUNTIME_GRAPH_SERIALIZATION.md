# Runtime Graph Serialization

Runtime Graph serialization protects schema state, diagnostics, and snapshots.

Authoritative records reject Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized node counts, and deep payloads. Diagnostic copies sanitize unsafe values, service markers, remote markers, runtime object markers, callbacks, module references, Framework references, and execution-adapter markers.

Snapshots, diagnostics, and public exports are isolated deep copies.

Diagnostic copies never preserve raw functions, threads, userdata, Roblox Instances, cycles, service references, remote references, runtime objects, callbacks, module references, Framework references, Workspace paths, or execution adapters. Sensitive keys and values are redacted into boundary-safe markers.
