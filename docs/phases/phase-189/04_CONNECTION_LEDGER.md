# Phase 189 - Connection Ledger

All runtime-owned `Activated` and `SelectionGained` connections enter one ledger. Reconciliation, unmount, and shutdown disconnect through the ledger. Diagnostics expose active, total-connected, total-disconnected, and a balance invariant: connected minus disconnected must equal active.

This makes leak claims measurable instead of inferred from source tokens.

## Ownership

Phase 189 owns accounting and cleanup of interaction-owned event connections.

## Non-Ownership

It does not inspect connections owned by unrelated PlayerGui systems or Roblox CoreGui.

## Certification Boundary

Repeated-revision and shutdown evidence must keep the ledger balanced.
