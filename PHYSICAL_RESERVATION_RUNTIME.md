# Physical Reservation Runtime

`PhysicalReservationRuntime` records reservation and execution lock schemas.

## Rules

- Reservations require a known `physicalObjectId`.
- `reservationId` is required and must be unique.
- `ownerSystem` is required.
- Duplicate reservations reject.
- Release operations require a known reservation.

## Boundary

Reservations are not physics locks and do not mutate Workspace. They are server-owned coordination records for future systems.
