# Session Validation

Session validation rejects malformed session schemas, unsupported schema types, duplicate session ids, duplicate player session ids, malformed party schemas, duplicate party ids, duplicate readiness ids, duplicate lifecycle ids, duplicate join/leave ids, unknown session references, malformed readiness records, malformed lifecycle records, malformed join/leave records, unsafe readiness/lifecycle/join-leave payloads, unsafe metadata/context/tags, Roblox Instances, unsafe runtime values, cycles, oversized payloads, and deep payloads.

It also rejects client/remote fields, Workspace fields, teleport and matchmaking execution fields, save persistence fields, lobby UI fields, party gameplay fields, Monster AI, Narrative, Horror, Chapter, story, dialogue, cutscene, UI, Audio, Lighting, and Camera fields.

## Reference Rules

Player session, party, readiness, lifecycle, and join/leave records must reference a registered session id. Unknown session references reject before state changes.
