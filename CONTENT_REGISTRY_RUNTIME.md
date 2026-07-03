# Content Registry Runtime

Phase 36 defines the server-authoritative Content Registry Runtime Foundation for London Engine.

The registry owns content schemas only. It gives future systems a safe catalog of content definitions, categories, references, dependencies, packages, versions, and tags without loading, spawning, streaming, executing, rendering, saving, or authoring final content.

## Responsibilities

- Store reusable content definition schemas.
- Store category, reference, dependency, package, version, and tag schemas.
- Enforce one global schema namespace across every content category.
- Reject malformed, duplicate, unsafe, oversized, cyclic, or execution-bearing payloads.
- Expose diagnostics, snapshots, serialization posture, runtime limits, and deterministic self-checks.
- Integrate with Bootstrap and Governance as a boundary runtime.

## Boundaries

Content Registry does not own Chapter content, Chapter 0 content, final story, final dialogue, asset loading, map loading, room loading, content streaming, content spawning, Workspace mutation, gameplay execution, puzzle/interaction/inventory execution, objective completion, narrative execution, save persistence, DataStore reads/writes, HttpService, MessagingService, remotes, client authority, analytics collection, or telemetry sending.

Future loaders, streamers, spawners, presentation systems, chapter systems, and save systems must consume approved registry schema data through governed interfaces. They must not hide execution adapters inside registry records.

## Runtime Shape

`ContentRegistryCoordinator` is the public service. Category-specific runtime modules delegate into `ContentState`, which validates through `ContentValidation` and clones through `ContentSerialization`.

All accepted records are deep-copied before storage. Diagnostics and snapshots are also deep-copied, so callers cannot mutate internal registry state.

## Server Authority

The server owns registry truth. There are no client remotes and no client-owned content records. Client presentation may later display approved derived data, but clients never define or mutate registry state.

## Certification Rules

Content Registry is content identity infrastructure only.

- Content definitions are registry records, not real content.
- Categories are classification schemas, not loaded content.
- References are schema links, not runtime object references.
- Dependencies are schema dependencies, not load-order execution.
- Packages are groups, not asset bundles.
- Versions are compatibility records, not migrations or patch execution.
- Tags are metadata, not gameplay behavior.
- Diagnostics are health-only, not content analytics.
- Snapshots are schema data, not content exports.

Future content loading, asset loading, map loading, room loading, content streaming, content spawning, Chapter content, story/dialogue writing, and gameplay execution must be separate governed systems. Future consumers must treat registry schemas as identifiers and constraints, not commands.
