# Transaction and Rollback
## Ownership
The runtime captures originals before each write and restores completed writes in strict reverse order after failure.
## Non-Ownership
Rollback does not repair foreign mutation or recreate destroyed instances.
## Certification Boundary
Write and rollback failure behavior must be demonstrated in Studio.
