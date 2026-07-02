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
