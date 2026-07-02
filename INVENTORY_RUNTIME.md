# Inventory Runtime Foundation

Phase 25 creates the server-authoritative schema layer for future London Engine inventory systems. It records inventory profiles, item definitions, slots, ownership records, capacity policies, eligibility records, item state schemas, diagnostics, snapshots, validation, serialization, and self-checks.

This runtime does not pick up items, use items, unlock doors, solve puzzles, persist save data, render inventory UI, mutate Workspace, create remotes, trust client authority, or contain Chapter content.

Future gameplay systems may reference inventory schema ids after they pass their own Governance contracts. They must not treat this foundation as an execution service.

## Runtime Modules

- `InventoryCoordinator` owns lifecycle integration, diagnostics registration, snapshot provider registration, and the public registration API.
- `InventoryProfileRuntime` stores bounded server-owned schema state.
- `InventoryItemRuntime` registers item schemas only.
- `InventorySlotRuntime`, `InventoryOwnershipRuntime`, `InventoryCapacityRuntime`, and `InventoryEligibilityRuntime` validate focused schema slices.
- `InventoryValidation` rejects malformed, unsupported, client-shaped, execution-shaped, and unsafe schemas before state changes.
- `InventorySerialization` deep-copies and sanitizes payloads.
- `InventorySelfChecks` proves the runtime remains schema-only.

## Server Authority

All inventory truth is server-owned. Clients have no remotes in this phase and cannot create, mutate, equip, use, consume, save, or present inventory through this runtime.

## Integration

Inventory is registered with Framework, Diagnostics, SnapshotManager, EventBus, and Governance. It depends conceptually on Physical, Interaction, Puzzle, Gameplay Execution, and Save schemas by id, but it does not execute or persist any of them.
