# Asset Governance Integration Serialization

Serialization accepts only bounded primitive data, arrays, and dictionaries that can be copied without runtime handles.

Serialization rejects:

- cycles
- userdata
- functions
- threads
- Instance-shaped tables
- oversized strings
- payloads deeper than `MaxPayloadDepth`
- payloads wider than `MaxPayloadNodes`
- service handles
- runtime handles
- asset handles
- loaded asset handles
- module references
- callbacks
- listeners
- execution adapters
- remotes
- forbidden execution/client/storage/content markers

Diagnostic copies sanitize unsafe markers instead of preserving executable or Roblox runtime-shaped values.

Serialized integration data remains metadata only. It does not become an asset loader, execution adapter, callback, event listener, remote payload, persistence payload, upstream mutation handle, or client authority surface.
