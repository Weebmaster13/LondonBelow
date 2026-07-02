# Analytics Validation

Analytics validation rejects malformed records, unsupported schema types, duplicate ids across one global analytics schema namespace, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- Telemetry sending fields
- External analytics fields
- Player tracking fields
- Moderation fields
- Profiling execution fields
- HTTP service fields
- DataStore fields
- Messaging service fields
- Remote and client fields
- UI, Workspace, and gameplay fields
- Chapter, story, dialogue, and cutscene fields

Validation never collects analytics, sends telemetry, tracks players, reports externally, moderates, profiles, calls HTTP, writes DataStores, publishes messages, creates remotes, trusts clients, mutates Workspace, executes gameplay, or adds Chapter content.
