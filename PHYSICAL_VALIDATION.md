# Physical Validation

`PhysicalValidation` is the safety boundary for Physical Runtime.

## Rejections

Validation rejects:

- missing ids
- duplicate ids
- invalid object types
- Workspace references
- Roblox Instances
- functions
- threads
- userdata
- cyclic tables
- oversized payloads
- oversized strings
- deep payloads
- movement fields
- animation fields
- combat fields
- pathfinding fields
- navigation fields
- monster fields
- dialogue fields
- story fields
- Chapter fields
- cutscene fields
- UI fields
- lighting fields
- audio fields
- client fields
- remote fields
- physics execution fields

## Intent

Validation keeps the runtime a schema store. It prevents future systems from smuggling execution behavior into physical object data.
