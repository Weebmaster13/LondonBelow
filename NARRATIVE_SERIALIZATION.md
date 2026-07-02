# Narrative Serialization

Narrative serialization exists to keep schema data portable, inspectable, and safe for diagnostics and snapshots.

## Accepted Data

Narrative schemas may contain plain serializable Luau values: strings, numbers, booleans, nil, and bounded tables.

## Rejected Data

Serialization rejects:

- Roblox Instances
- cyclic tables
- functions
- threads
- userdata
- oversized strings
- overly deep payloads
- oversized node counts

Rejected payloads are sanitized before diagnostics store them. Diagnostics never keep raw unsafe runtime references.

## Isolation

Exports use deep copies. A caller modifying a returned diagnostic table or snapshot must not mutate Narrative Runtime state.

## Design Boundary

Serialization protects schema transport only. It does not authorize final story presentation, cutscenes, UI, audio, lighting, Workspace mutation, Monster AI, or horror pacing.
