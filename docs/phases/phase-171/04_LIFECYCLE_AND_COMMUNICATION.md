# Lifecycle And Communication

Domain lifecycle is integrated through the Phase 170 Runtime Capability Framework.

Phase 171 records lifecycle metadata for registered, initialized, ready, active, suspended, and recovery-capable domain capabilities. It does not execute domain gameplay.

Communication contracts are metadata only:

- commands are submit-only;
- events are observe-only;
- queries are consume-only;
- direct capability calls are disallowed.

Workflow participation is explicit and bounded to `None`, `Observer`, `Participant`, or `Coordinator`.
