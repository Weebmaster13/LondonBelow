# Director Coordinator

`DirectorCoordinator` is the lifecycle and routing owner for the Director Ecosystem.

It owns:

- Director discovery and registration.
- Director startup and shutdown order.
- Contract validation.
- Observation routing from `ObservationService`.
- Typed request submission.
- Approval, rejection, deferral, modification, expiration, and cancellation records.
- Conflict metrics.
- Diagnostics and snapshots.

It does not own gameplay, Monster AI, final audio, final lighting, final UI, art, or chapter content.

## Failure Isolation

Director calls are wrapped with protected calls. If one Director fails while observing or handling approval, the Coordinator publishes failure diagnostics and continues routing to other Directors.

## Request Resolution

The Coordinator can resolve requests itself when cross-domain context matters. For example, a `RequestMonsterReveal` can be deferred when `requiredNarrativeBeat` does not match the current narrative beat, while a `RequestLightingChange` can be approved as lower-risk atmosphere pressure.

## Diagnostics

Coordinator diagnostics include:

- Registered Directors.
- Director health.
- Capabilities.
- Pending requests.
- Recent responses.
- Routed observations.
- Approval counts.
- Rejected, deferred, modified, expired, and cancelled counts.
- Conflict counts.
- Average request time.

