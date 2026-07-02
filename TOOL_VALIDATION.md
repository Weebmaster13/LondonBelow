# Tool Validation

Developer Tooling validation rejects malformed records, duplicate ids, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- Command execution fields
- Admin power fields
- Remote console fields
- Moderation fields
- Analytics collection fields
- Exploit and backdoor fields
- DataStore fields
- Workspace fields
- Remote and client fields
- Teleport, gameplay execution, and save mutation fields
- Chapter, story, dialogue, and cutscene fields

Validation is defensive and schema-only. It never executes tools, commands, admin powers, moderation actions, analytics collection, DataStore access, Workspace mutation, remotes, client authority, or Chapter content.
