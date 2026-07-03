# Content Registry Serialization

Content Registry serialization exists to protect state, diagnostics, snapshots, and future tooling.

All accepted records are deep-copied before storage. Diagnostics and snapshots are deep-copied before being returned. Unsafe runtime values are rejected for authoritative records and sanitized in diagnostic copies.

Serialization rejects:

- Roblox Instances
- functions
- threads
- userdata
- cyclic tables
- oversized strings
- oversized node counts
- deep payloads

This keeps the registry portable, inspectable, and safe for future save/export tooling without granting persistence authority.

## Diagnostic Sanitization

Diagnostic copies sanitize unsafe runtime values and boundary-sensitive content markers. They never preserve raw functions, threads, userdata, Roblox Instances, cycles, service references, remote references, asset handles, loading handles, streaming handles, spawn handles, Workspace paths, or execution-adapter markers.

Snapshots, diagnostics, and public exports are isolated deep copies. Callers cannot mutate registry source-of-truth tables through returned data.
