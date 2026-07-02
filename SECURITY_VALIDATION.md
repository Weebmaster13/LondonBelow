# Security Validation

Security validation rejects malformed records, missing ids, malformed ids, unsupported schema types, duplicate ids across one global security schema namespace, unsafe metadata, unsafe context, unsafe tags, Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized payloads, and overly deep payloads.

It also rejects:

- live anti-cheat fields;
- exploit detection execution fields;
- ban and kick fields;
- moderation fields;
- punishment fields;
- client monitoring fields;
- `RemoteEvent` and `RemoteFunction` fields;
- remote creation fields;
- client authority fields;
- DataStore fields;
- analytics and telemetry fields;
- player tracking fields;
- Workspace and gameplay execution fields;
- Chapter, story, dialogue, and cutscene fields.

Validation protects schema boundaries only. It does not detect exploits, enforce security, punish players, monitor clients, create remotes, write DataStores, collect analytics, send telemetry, mutate Workspace, execute gameplay, or add Chapter content.

## Hardened Validation

Validation rejects forbidden fields anywhere in metadata, context, tags, nested tables, table keys, and string values where applicable. This includes live anti-cheat, detection, enforcement, moderation, punishment, monitoring, remote, client authority, DataStore, analytics, telemetry, tracking, HTTP, messaging, service reference, adapter reference, handler reference, Workspace, gameplay, and Chapter/story/dialogue/cutscene fields.

All schema ids share one global security namespace. Duplicate rejection happens before state mutation, is deterministic, and is recorded only as sanitized validation diagnostics.
