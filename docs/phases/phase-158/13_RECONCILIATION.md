# Reconciliation

Reconciliation verifies:
- each Chapter 0 fixture has a local binding record;
- Environmental Interaction Runtime reconciliation succeeds;
- registered environmental objects still have Phase 156 interaction targets;
- registered environmental actions still have Phase 156 interaction schemas.

Drift reports `CHAPTER0_ENVIRONMENTAL_RECONCILIATION_FAILED` or `RECONCILIATION_FAILED` without fabricating readiness.
