# Ownership And Reservation

`RobloxRendererOwnership` records renderer ownership metadata:

- `rendererId`
- `currentSession`
- `reservationOwner`
- `assignmentOrdinal`
- `ownershipVersion`
- `runtimeMetadata`

`RobloxRendererReservation` prevents multiple sessions from claiming the same renderer. Reservation states are `None`, `Reserved`, `Active`, `Released`, and `Expired`.

Reservations and ownership are metadata-only and do not instantiate or mutate Roblox renderer objects.
