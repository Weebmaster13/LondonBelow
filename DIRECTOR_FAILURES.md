# Director Failures

Director failures must be isolated so one weak subsystem cannot collapse the London Engine.

## Failure Rules

- Unknown target Directors are rejected with a structured approval.
- Malformed requests are rejected and traced.
- Expired requests return `Expired`.
- Target Director errors are caught by `DirectorRouter`.
- Target Director approvals are validated before they are trusted.
- Invalid approval statuses are rejected with diagnostics.
- Observation routing uses protected calls per Director.
- Pending request expiration is swept by the Coordinator.
- Shutdown cancels Scheduler work, disconnects EventBus subscriptions, and clears pending requests.

## Safe Defaults

When the Director Ecosystem cannot make a safe decision, it should defer, reject, or stay silent. It must not invent gameplay truth, force client presentation, or bypass future execution systems.
