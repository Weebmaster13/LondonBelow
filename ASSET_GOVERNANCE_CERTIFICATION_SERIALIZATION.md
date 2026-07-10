# Asset Governance Certification Serialization

Serialization accepts only bounded primitive data, arrays, and dictionaries that can be copied without runtime handles.

Serialization rejects cycles, userdata, functions, threads, Instance-shaped tables, oversized strings, excessive depth, excessive node count, service handles, runtime handles, asset handles, loaded asset handles, module references, callbacks, listeners, execution adapters, remotes, orchestration markers, scheduling markers, repair markers, authorization markers, and forbidden execution/client/storage/content markers.

Diagnostic copies sanitize unsafe markers and values.

Phase 62 hardening verifies forbidden markers both as table keys and as string values. The serializer treats certification metadata as plain data only; it never stores Roblox Instances, service references, callbacks, listeners, modules, asset handles, loaded assets, execution adapters, or other live runtime objects.

Current bounded payload limits are:

- `MaxPayloadDepth = 8`
- `MaxPayloadNodes = 450`
- `MaxStringLength = 280`

Serialization is used by validation before mutation, by state deep copies, by diagnostics failure sanitization, and by snapshot isolation. It is not an asset loader, persistence format, network protocol, or execution adapter.
