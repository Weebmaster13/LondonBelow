# Asset Governance Certification Serialization

Serialization accepts only bounded primitive data, arrays, and dictionaries that can be copied without runtime handles.

Serialization rejects cycles, userdata, functions, threads, Instance-shaped tables, oversized strings, excessive depth, excessive node count, service handles, runtime handles, asset handles, loaded asset handles, module references, callbacks, listeners, execution adapters, remotes, orchestration markers, scheduling markers, repair markers, authorization markers, and forbidden execution/client/storage/content markers.

Diagnostic copies sanitize unsafe markers and values.
