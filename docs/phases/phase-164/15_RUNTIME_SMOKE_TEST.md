# Runtime Smoke Test

Runtime Smoke Test: blocked by environment

The required smoke flow is defined:

1. Initialize Event Bus.
2. Register `core.event.test`.
3. Register test publisher.
4. Register test subscriber.
5. Publish, validate, queue, route, and dispatch.
6. Verify exactly-once subscriber receipt for runtime-local delivery.
7. Verify priority ordering and equal-priority FIFO ordering.
8. Unsubscribe and shut down.

Static Node automation is not authoritative Roblox Studio execution. Phase 164 remains Production Candidate until runtime evidence is imported through the Runtime Execution Framework.
