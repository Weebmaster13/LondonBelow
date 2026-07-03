# Content Registry Validation

`ContentValidation.lua` is the first safety boundary for Phase 36.

It rejects:

- missing or malformed ids
- unsupported schema types
- unsupported content domains
- duplicate ids through `ContentState`
- malformed references, dependencies, packages, versions, and tags
- unknown reference, dependency, package, and version endpoints through `ContentState`
- unsafe metadata, context, and tags
- Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, and deep payloads
- Chapter content, Chapter 0 content, final story, final dialogue, asset loading, map loading, room loading, content streaming, content spawning, Workspace mutation, gameplay execution, puzzle/interaction/inventory execution, objective completion, narrative execution, save persistence, DataStore, HttpService, MessagingService, remotes, client authority, analytics collection, telemetry sending, service references, adapter references, handler references, and execute fields

Validation is intentionally conservative. If a future system needs executable behavior, it must create a separate governed runtime and consume registry records as data.
