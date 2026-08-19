# Phase 187 - Ownership and Integrity

The integrity guard verifies root ownership, contract and revision attributes, descendant membership, node identity, and exact runtime-owned cardinality before replacement and on demand.

## Ownership

Phase 187 owns integrity checks for its active local tree.

## Non-Ownership

It does not inspect or mutate unrelated PlayerGui children.

## Certification Boundary

Integrity failures reject work and never imply server compromise.
