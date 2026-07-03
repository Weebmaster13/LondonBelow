# Schedule Slot Runtime

Slots are schema positions, not frame slots.

Slot records describe planned ordering or grouping positions for future scheduler design. They do not bind to frames, ticks, RunService callbacks, or live scheduling loops.

Slots reject malformed ids, unsafe payloads, and frame-scheduling markers.

## Hardening Rules

Slots reject frame scheduling, tick execution, heartbeat, stepped, renderStepped, RunService, task handles, timer handles, and coroutine handles. A slot is a schema position only; it cannot become a live frame slot or loop.
