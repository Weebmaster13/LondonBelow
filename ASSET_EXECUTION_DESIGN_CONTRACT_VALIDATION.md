# Asset Execution Design Contract Validation

Validation occurs before mutation. Failed validation records a bounded, sanitized failure and leaves state unchanged.

The validator rejects nil and non-table schemas, invalid ids, unsupported schema types, unsupported contract kinds, unsupported contract statuses, unsupported responsibility kinds, unsupported boundary kinds, unsupported audit kinds, unsupported audit statuses, missing contract references, unsafe metadata, unsafe tags, unsafe findings, Roblox Instances, instance-shaped tables, functions, threads, userdata, callbacks, listeners, service handles, runtime handles, asset handles, loaded asset handles, module references, execution adapters, remotes, cycles, oversized strings, deep payloads, and oversized node counts.

Forbidden markers cover asset loading, preloading, streaming, spawning, application, playback, UI, VFX, storage mutation, client authority, remotes, DataStore, HTTP, messaging, analytics, telemetry, gameplay execution, Presentation execution, Save execution, Chapter content, maps, rooms, dialogue, and cutscenes.
