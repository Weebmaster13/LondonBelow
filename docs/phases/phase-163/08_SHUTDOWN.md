# Shutdown

Graceful shutdown closes active sessions where possible, clears active transactions, releases locks, records shutdown evidence, and clears bounded runtime state.

Shutdown does not force gameplay changes or write storage directly.
