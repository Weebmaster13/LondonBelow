# Sessions And Queue

`PresentationSessionRegistry` owns presentation session metadata.

`PresentationQueue` manages queued, assigned, suspended, and cancelled session ids. Ordering is deterministic by priority, queue ordinal, and stable identifier.

Queue operations validate before mutation and never bypass lifecycle checks.
