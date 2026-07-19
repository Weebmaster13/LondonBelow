# Backend Lifecycle Integration

Phase 152 extends lifecycle vocabulary with:

- `PlacePrepared`
- `WaitingForManualAction`
- `ExecutionBlocked`
- `ExecutionFailed`
- `TimedOut`
- `Cancelled`
- `CleanupFailed`

The framework validates canonical, manual, and blocked lifecycle paths and rejects illegal transitions.

The Phase 152 smoke path reaches manual handoff and preserves blocked runtime truth because no structured runtime result was imported.
