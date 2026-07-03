# Content Definition Runtime

Content definitions describe catalog entries for future London Engine content. A definition can identify a chapter-facing concept, room-facing schema, item schema, puzzle schema, interaction schema, objective schema, narrative schema, localization schema, presentation schema, monster schema, entity schema, accessibility schema, save schema, session schema, world schema, or system schema.

Definitions are not content instances. They do not include final story, final dialogue, room layouts, final puzzle content, final items, monster behavior, asset handles, streaming instructions, spawning instructions, or execution adapters.

Each definition requires:

- `contentId`
- `ownerSystem`
- `contentDomain`
- optional `dependencyIds`
- optional `referenceIds`
- optional `packageIds`
- optional `metadata`
- optional `context`
- optional `tags`

Definitions are validated for supported domains, safe metadata/context/tags, bounded link counts, and duplicate id rejection.

## Hardening Notes

Definitions are registry records, not real content. They cannot contain final Chapter content, story, dialogue, room layouts, puzzle content, item content, objective content, monster behavior, asset handles, loading handles, streaming handles, spawn handles, service references, remotes, Workspace paths, or execution adapters.

Future systems may use a definition id to look up governed policy, but the definition itself must never be treated as an instruction to load, spawn, stream, save, render, or execute content.
