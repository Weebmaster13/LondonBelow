# Persistence Validation

Persistence validation rejects malformed requests, duplicate request ids, duplicate package ids, malformed migration schemas, malformed write policies, malformed retry policies, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects client/remote fields, DataStore execution fields, live persistence fields, profile loading fields, cloud save fields, migration execution fields, save mutation fields, Workspace fields, gameplay execution fields, UI fields, Chapter/story/dialogue/cutscene fields, and anything shaped like live persistence behavior.
