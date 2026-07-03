# Content Registry Self-Checks

`ContentSelfChecks.lua` proves Phase 36 behavior before startup.

Self-checks cover:

- malformed and duplicate records
- unsupported schema types and domains
- global namespace collisions across all content categories
- invalid reference, dependency, package, and version endpoints
- direct dependency cycles
- unsafe metadata, context, and tags
- forbidden final content, loading, streaming, spawning, execution, service, remote, client, save, analytics, telemetry, story, dialogue, and Chapter fields
- serialization rejection for cycles, Roblox Instances, functions, threads, oversized payloads, and deep payloads
- snapshot isolation
- diagnostics isolation
- bounded histories
- runtime limit rejection
- shutdown cleanup
- refusal to run destructive self-checks after start

Self-checks are not gameplay tests. They certify that the registry remains a schema boundary.
