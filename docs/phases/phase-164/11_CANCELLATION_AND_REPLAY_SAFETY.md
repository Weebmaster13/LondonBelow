# Cancellation and Replay Safety

Cancellation is supported before dispatch through `EventCancellationRuntime.lua`.

Events already entering subscriber delivery do not report successful cancellation.

Replay safety is metadata only in Phase 164. `ReplaySafe`, `ReplayUnsafe`, and `ReplayMetadataOnly` describe future replay eligibility; no replay executor or durable event store is implemented.
