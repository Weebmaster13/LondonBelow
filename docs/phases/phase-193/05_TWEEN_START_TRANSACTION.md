# Phase 193 - Tween Start Transaction
## Ownership
Property reservations and the active record are published before Play only so synchronous completion is observable. If Play fails, cancellation disconnects, restores captured values, releases reservations, and returns a structured failure.
## Non-Ownership
A failed Tween start never remains active or consumes ownership.
## Certification Boundary
Studio must inject Play failure and prove restoration, balance, and subsequent recovery.
