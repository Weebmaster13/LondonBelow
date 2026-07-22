# Architecture

Runtime Event Bus is Core infrastructure. Domain runtimes may publish authoritative facts into it, but the Event Bus does not own those facts.

Events represent facts. Commands request work. Queries request information.

Phase 164 implements events only.

The final Bootstrap relationship is:

`Logger`, `EventBus`, `Diagnostics`, `SnapshotManager` -> `RuntimeEventBusCoordinator` -> domain coordinators.

The legacy `Core/EventBus.lua` module remains the compatibility facade so existing systems continue to depend on `EventBus` without being rewritten in this phase.
