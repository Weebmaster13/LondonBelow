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
