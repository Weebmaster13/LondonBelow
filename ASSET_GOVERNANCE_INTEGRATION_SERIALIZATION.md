# Asset Governance Integration Serialization

Serialization accepts only bounded primitive data, arrays, and dictionaries that can be copied without runtime handles.

Diagnostics and snapshots use isolated deep copies. Diagnostic copies sanitize unsafe markers instead of preserving executable or Roblox runtime-shaped values.

Serialization rejects cycles, userdata, functions, threads, Instance-shaped tables, oversized strings, payloads deeper than `MaxPayloadDepth`, and payloads wider than `MaxPayloadNodes`.

Serialized integration data remains metadata only. It does not become an asset loader, execution adapter, callback, event listener, remote payload, persistence payload, upstream mutation handle, or client authority surface.
