# Physical Ownership Runtime

`PhysicalOwnershipRuntime` tracks which server system owns a physical schema.

## Rules

- Ownership is authority metadata only.
- Ownership does not grant gameplay execution.
- Invalid owner ids reject.
- Unknown object ids reject.

## Future Use

Future systems can use ownership to coordinate who may request reservations or execution plans. They must still go through Governance and the Gameplay Execution Bridge before physical or presentation behavior exists.
