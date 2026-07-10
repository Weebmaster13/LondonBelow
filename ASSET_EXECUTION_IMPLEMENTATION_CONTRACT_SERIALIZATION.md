# Asset Execution Implementation Contract Serialization

Serialization accepts only bounded primitive data, arrays, and dictionaries that can be copied without runtime handles.

Implementation contract snapshots and diagnostics use isolated deep copies. Diagnostic copies sanitize unsafe markers instead of preserving executable or Roblox runtime-shaped values.

Serialization rejects cycles, userdata, functions, threads, instance-shaped tables, oversized strings, payloads deeper than `MaxPayloadDepth`, and payloads wider than `MaxPayloadNodes`.

Serialized implementation contract data remains metadata only. It does not become an asset loader, execution adapter, callback, event listener, remote payload, persistence payload, or client authority surface.

Phase 58 treats serialized diagnostics and snapshots as integration-readiness evidence only. They remain isolated copies and do not contain upstream runtime handles.
