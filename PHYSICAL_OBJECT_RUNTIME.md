# Physical Object Runtime

`PhysicalObjectRuntime` is the bounded state store for physical object schemas.

## Physical Object Schema

Each registered object stores:

- `physicalObjectId`
- `objectType`
- `schemaVersion`
- `ownerSystem`
- `registeredAt`
- `state`
- `reservationState`
- `transformSchema`
- `tags`
- `metadata`

## Rules

- No Roblox Instances are stored.
- Public exports are deep copies.
- Registered object history is bounded.
- Removing an object clears associated ownership, transform, and reservation records.

## Boundary

Physical Object Runtime describes objects. It does not implement door logic, drawer logic, movement, physics, interactions, or visual presentation.
