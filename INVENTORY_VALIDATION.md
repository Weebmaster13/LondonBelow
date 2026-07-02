# Inventory Validation

Inventory validation is the primary enforcement boundary for Phase 25.

It rejects:

- malformed profile and item schemas
- unsupported profile and item types
- duplicate profile and item ids
- malformed or duplicate slots
- invalid ownership, capacity, eligibility, and item state records
- unsafe metadata, context, and tags
- client, remote, Workspace, Instance, execution, UI, Audio, Lighting, Camera, Animation, Monster AI, Narrative, Save, Horror, Chapter, story, dialogue, and cutscene fields

Validation must run before state changes. Future systems must not bypass `InventoryCoordinator` or the focused validation modules.
