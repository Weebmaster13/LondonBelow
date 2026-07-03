# Content Registry Diagnostics

Diagnostics expose health-only information:

- initialized and started state
- lifecycle state
- content, category, reference, dependency, package, version, and tag counts
- validation failure count
- snapshot count
- runtime limits
- serialization posture
- snapshot isolation proof
- diagnostics isolation proof
- no-execution posture
- recent sanitized validation failures
- last self-check result

Diagnostics never expose loading adapters, service handles, remotes, Workspace references, final content, story, dialogue, or execution handles.

## Certification Posture

Diagnostics expose reference, dependency, package, and version integrity posture. They also expose no-execution proof for no Chapter content, no Chapter 0 content, no final story/dialogue, no final room layouts, no final puzzles/items/objectives/monster behavior, no asset/map/room loading, no content streaming/spawning, no package loading, no content authoring, no Workspace mutation, no gameplay/puzzle/interaction/inventory execution, no objective completion, no narrative execution, no save persistence, no DataStore reads/writes, no HttpService, no MessagingService, no remotes, no client authority, no analytics collection, and no telemetry sending.

Diagnostics are health-only. They are not content analytics, content export tooling, asset loading tooling, or Chapter tooling.
