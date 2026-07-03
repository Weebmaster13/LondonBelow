# Schedule Slot Runtime

Slots are schema positions, not frame slots.

Slot records describe planned ordering or grouping positions for future scheduler design. They do not bind to frames, ticks, RunService callbacks, or live scheduling loops.

Slots reject malformed ids, unsafe payloads, and frame-scheduling markers.
