# Phase 193 - Property Ownership Integrity
## Ownership
The integrity guard proves every property owner maps to an active record, every active record owns each declared key, and the lifecycle ledger exactly matches active records.
## Non-Ownership
The guard never repairs corruption silently or expands ownership.
## Certification Boundary
Injected orphan, missing reservation, mismatch, and missing-connection cases must fail closed.
