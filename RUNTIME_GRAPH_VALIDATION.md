# Runtime Graph Validation

Validation rejects malformed ids, duplicate ids across the global Runtime Graph namespace, unsupported schema types, unsupported runtime layers, unsupported dependency, ordering, and compatibility kinds, missing endpoints, self-dependencies, direct required cycles, self-ordering, direct ordering contradictions, unsafe metadata, unsafe context, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, deep payloads, and forbidden execution/lifecycle/service/client/content fields.

Forbidden fields reject in metadata, context, tags, nested tables, table keys, and string values.

The forbidden set includes startup/shutdown/initialization execution, require calls, module loading, dependency injection, service resolution, Framework replacement, Framework mutation, runtime API calls, lifecycle execution, orchestration execution, content/asset/map/room loading, Workspace mutation, remotes, client authority, gameplay/puzzle/interaction/inventory/objective/narrative/Monster AI/Presentation execution, Save persistence, DataStore, HTTP, messaging, analytics, telemetry, Chapter content, story, dialogue, cutscenes, service references, adapter references, handler references, callbacks, module references, Framework references, runtime objects, Workspace paths, instance references, and execute fields.
