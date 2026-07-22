# Runtime Event Coordination

`RuntimeEventCoordinator` records internal dialogue runtime event coordination records for interaction creation, waiting, validation, application, cancellation, timeout, resume, and nested conversation transitions.

This is not the Runtime Event Bus and does not publish engine-wide events. Phase 174 only coordinates dialogue interaction evidence so later presentation contracts can consume authoritative state safely.
