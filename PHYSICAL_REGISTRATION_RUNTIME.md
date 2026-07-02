# Physical Registration Runtime

`PhysicalRegistrationRuntime` validates and registers physical object schemas.

## Registration Rules

- `physicalObjectId` is required.
- `objectType` must be supported.
- `schemaVersion` is required.
- `ownerSystem` is required.
- Duplicate ids reject.
- Unsafe payloads reject before state changes.

## Supported Schema Types

- `PhysicalObject`
- `DoorPhysicalSchema`
- `DrawerPhysicalSchema`
- `ElevatorPhysicalSchema`
- `PuzzlePhysicalSchema`
- `InteractablePhysicalSchema`
- `PropPhysicalSchema`
- `EnvironmentPhysicalSchema`
- `HidingSpotPhysicalSchema`

These names are schema categories only. They do not implement gameplay.
