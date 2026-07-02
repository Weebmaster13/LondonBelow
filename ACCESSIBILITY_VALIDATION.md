# Accessibility Validation

Accessibility validation rejects malformed records, unsupported schema types, duplicate ids across one global accessibility schema namespace, unsafe payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects:

- Client and remote fields
- Final UI fields
- Input remapping execution fields
- Audio, lighting, camera, and VFX execution fields
- Workspace and gameplay fields
- Chapter, story, dialogue, and cutscene fields

Validation never creates UI, applies client settings, remaps input, executes audio, mutates lighting, moves cameras, plays VFX, mutates Workspace, creates remotes, trusts clients, executes gameplay, or adds Chapter content.
