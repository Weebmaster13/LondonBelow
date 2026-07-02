# World Validation

World validation rejects malformed schemas, duplicates, unsupported or unsafe structures, invalid streaming policies, invalid connection endpoints, malformed references, unsafe metadata/context, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and overly deep payloads.

It also rejects fields associated with Workspace mutation, terrain, CFrame execution, teleporting, movement, pathfinding, physics, map generation, room loading, streaming execution, interaction execution, puzzle execution, inventory execution, Monster AI, Narrative, Save, Horror, UI, Audio, Lighting, Camera, remotes, clients, Chapter content, story, dialogue, and cutscenes.

## Reference Rules

- Buildings may reference only registered district ids.
- Floors may reference only registered building ids.
- Rooms may reference only registered building and floor ids.
- Zones may reference only registered room ids when `roomId` is present.
- Connections may reference only registered world ids for both endpoints.
- Streaming regions may reference only registered world ids.

References are validated during registration because shape validation alone cannot know which ids are already registered.
