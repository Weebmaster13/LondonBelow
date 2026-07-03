# Lifecycle Checkpoint Runtime

Checkpoints are lifecycle metadata, not save persistence.

Checkpoint records describe lifecycle state markers for future review. They do not write DataStores, persist player state, capture live runtime objects, or serialize Roblox Instances.

## Hardening Rules

Checkpoints reject unsupported lifecycle states, save persistence payloads, DataStore payloads, live runtime object payloads, Roblox Instance payloads, Workspace references, and service handles. They are lifecycle metadata only, not Save Runtime records and not persistence operations.
