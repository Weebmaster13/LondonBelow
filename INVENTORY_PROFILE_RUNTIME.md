# Inventory Profile Runtime

Inventory profiles describe a future inventory container owned by the server. A profile contains:

- `inventoryProfileId`
- `ownerSystem`
- `profileKind`
- `capacity`
- `slots`
- optional metadata, context, and tags

Profiles are schema records only. They do not represent a live client backpack, final UI state, DataStore profile, or Chapter inventory.

Duplicate profile ids reject. Unsupported profile kinds reject. Unsafe metadata, context, client fields, remotes, Workspace references, execution fields, story fields, and Chapter fields reject.
