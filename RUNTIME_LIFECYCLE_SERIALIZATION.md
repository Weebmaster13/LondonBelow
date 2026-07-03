# Runtime Lifecycle Serialization

Runtime Lifecycle serialization protects schema state, diagnostics, and snapshots.

Authoritative records reject Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized node counts, and deep payloads. Diagnostic copies sanitize unsafe values, service references, remote references, runtime objects, callbacks, module references, Framework references, Workspace paths, live lifecycle markers, live service handles, and execution adapters.

Snapshots, diagnostics, and public exports are isolated deep copies.

## Hardened Serialization Boundary

Serialization now treats keys and values as equally untrusted. Diagnostic copies must never preserve raw functions, threads, userdata, Instances, cycles, service references, remote references, runtime objects, callbacks, module references, Framework references, Runtime Graph references, Workspace paths, live lifecycle state, live service handles, live error objects, secret stack traces, or execution adapters.

Serialization is safety infrastructure only. It does not repair bad payloads, load modules, resolve services, call runtime APIs, execute lifecycle behavior, emit events, or mutate state outside the schema store.
