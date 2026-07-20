# Rollback

Rollback behavior:
- unregister environmental object definitions;
- unregister Phase 156 interaction schemas created by the environmental runtime;
- unregister Phase 156 interaction targets created by the environmental runtime;
- record a bounded failure/evidence entry;
- leave Chapter 0 readiness blocked when registration cannot complete.

Rollback does not mutate Workspace, client state, persistence, analytics, telemetry, or external services.
