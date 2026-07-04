# Asset Readiness Review Validation

Validation happens before mutation. Failed validation records a bounded, sanitized failure and does not change runtime state.

The validator rejects nil and non-table schemas, invalid ids, unsupported schema types, unsupported checklist kinds, unsupported readiness tiers, unsupported finding/gate/decision/audit kinds, unsupported statuses, unsupported severities, missing checklist references, unsafe tags, unsafe metadata, unsafe findings, cycles, oversized strings, deep payloads, oversized node counts, Roblox Instances, functions, threads, userdata, service handles, runtime handles, asset handles, module references, callbacks, remotes, listeners, and execution adapters.

Forbidden markers include loading, preloading, content service, insert service, marketplace service, model spawning, UI creation, VFX creation, sound/animation/mesh/texture/material/decal loading, Workspace mutation, ReplicatedStorage mutation, ServerStorage mutation, remotes, client authority, DataStore, HTTP, messaging, analytics, telemetry, gameplay execution, Presentation execution, Save execution, Chapter content, maps, rooms, dialogue, and cutscenes.
