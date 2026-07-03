# Condition Self-Checks

Condition self-checks certify malformed schema rejection, unsupported type rejection, unsupported domain rejection, unsupported operator rejection, invalid references, duplicate rejection, global namespace collision rejection, self dependency rejection, direct cycle rejection, forbidden field rejection, serialization rejection, snapshot isolation, diagnostic isolation, no-execution posture, bounded histories, and shutdown cleanup.

Self-checks must run before start. They are deterministic schema tests, not gameplay tests and not live evaluation.

Passing self-checks means the foundation is safe as a schema boundary. It does not mean a future condition evaluator exists.

## Production Hardening

The hardened self-check suite covers every schema category, duplicate rejection, invalid references, global namespace collisions, forbidden marker rejection in keys and values, unsafe serialization rejection, bounded histories, bounded snapshots, category limits, snapshot isolation, diagnostic isolation, no-execution posture, shutdown cleanup, and global namespace reset.
