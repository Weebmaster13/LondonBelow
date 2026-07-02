# Inventory Diagnostics

Inventory diagnostics expose runtime health without leaking mutable state.

Diagnostics include:

- initialized and started lifecycle state
- profile, item, slot, ownership, capacity, eligibility, validation failure, and snapshot counts
- runtime limits
- validation health
- recent sanitized validation failures
- explicit no-execution posture

Diagnostics are read-only copies. They are safe for Framework health checks and future developer tooling.
