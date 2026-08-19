# Phase 187 - Revision and Idempotency

Equal identity and revision remain idempotent. Lower revisions reject as stale before staging, preventing rollback to older visual state.

## Ownership

Phase 187 owns monotonic local reconciliation.

## Non-Ownership

It does not assign authoritative server revisions.

## Certification Boundary

Revision behavior must also pass the Studio matrix.
