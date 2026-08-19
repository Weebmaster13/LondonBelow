# Phase 188 - Reconciliation

The renderer validates interaction metadata before staging. Focus is captured while the previous tree is intact. The new root commits atomically, the Instance registry publishes it, and interaction reconciliation binds only the new controls. Old connections are disconnected before new bindings are installed.

Action callbacks are identity-based and remain registered across revisions, so visual replacements do not require re-registering application behavior.

## Ownership

Phase 188 owns control rebinding and focus continuity across successful Phase 186/187 root replacement.

## Non-Ownership

It does not perform partial GUI diffs, semantic form-data migration, or server-state reconciliation.

## Certification Boundary

Revision replacement must prove exactly-once bindings and no stale callbacks in Studio.
