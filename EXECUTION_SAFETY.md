# Execution Safety

Gameplay Execution Bridge safety rules are strict by design.

## Default Safety

- Default mode is `DryRun`.
- `PhysicalMutationEnabled` is `false`.
- Enabled mode is rejected while physical mutation is disabled.
- Missing adapters do not mutate anything.
- Failed, rejected, expired, and cancelled execution requests never alter gameplay truth.

## Validation

The bridge rejects:

- duplicate `executionId`
- untrusted `sourceSystem`
- missing `targetObjectId`
- unknown `executionKind`
- expired requests
- unsafe payload or metadata
- major execution kinds that lack approval metadata
- queue overflow
- object targets with active execution leases

Duplicate rejection does not change the original queued execution record.

## Multiplayer Protection

The bridge includes a per-object lock/lease foundation. This prevents future simultaneous adapter execution from racing on the same object. Locks expire and are cleared on shutdown.

## Dry-Run Meaning

Dry-run validates the request and marks it applied as a boundary proof. It does not move parts, change attributes, play audio, trigger effects, or modify gameplay truth.

## Future Enablement

Future real adapters must be reviewed, registered explicitly, and run only after the project has a physical execution policy for Studio-bound objects.
