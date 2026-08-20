# Phase 192 - Cancellation and Restoration
## Ownership
Explicit cancellation disconnects completion first, cancels the tween, optionally restores captured original values, releases property ownership, and audits the reason.
## Non-Ownership
Reconciliation cleanup never restores values into a retiring tree.
## Certification Boundary
Manual, superseded, reconciliation, unmount, and shutdown cancellation are Studio cases.
