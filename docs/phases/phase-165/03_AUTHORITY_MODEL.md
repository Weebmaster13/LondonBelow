# Authority Model

Each command type has exactly one owner runtime and one registered handler. Ambiguous ownership rejects at definition or handler registration time.

Every accepted command has an identifiable requester, owner, route, handler, result, diagnostics posture, and evidence trail.

No runtime should directly mutate another runtime's authoritative state without an approved command pathway.
