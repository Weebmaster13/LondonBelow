# Director Diagnostics

The Director Ecosystem exposes diagnostics through `DirectorCoordinator.inspect`.

Diagnostics include:

- Registered Directors.
- Missing required Directors.
- Director health.
- Capability maps.
- Pending request count.
- Recent approval responses.
- Average request time.
- Approval, rejection, deferral, modification, expiration, and cancellation counts.
- Recent Director failures.
- Decision traces.
- Conflict resolver state.

Snapshots are registered under `directorCoordinator`.

Diagnostics are server-side developer inspection data. They are not client gameplay truth and should not be replicated directly to players.
