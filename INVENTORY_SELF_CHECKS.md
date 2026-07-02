# Inventory Self-Checks

Inventory self-checks are destructive and should run before runtime start.

They prove:

- malformed and duplicate profiles reject
- unsupported profile types reject
- valid profiles register
- invalid capacity and slot schemas reject
- malformed, duplicate, and unsupported items reject
- valid items register
- invalid ownership, eligibility, and item state reject
- unsafe metadata, context, and tags reject
- client, remote, Workspace, execution, UI, Audio, Lighting, Camera, Animation, Monster AI, Narrative, Save, Horror, Chapter, story, dialogue, and cutscene fields reject
- serialization rejects cycles, unsafe runtime values, oversized payloads, and deep payloads
- snapshots are isolated
- diagnostics are read-only
- histories are bounded
- shutdown clears state
- no item pickup execution, item use execution, door unlocking, puzzle solving, save persistence, final UI, Workspace mutation, remotes, client authority, or Chapter content exists
