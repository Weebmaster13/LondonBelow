# Schedule Interval Runtime

Intervals are schema values, not ticking loops.

Interval records describe interval policy values for future scheduler design. They do not create loops, tick callbacks, RunService hooks, or frame updates.

Intervals reject malformed ids, unsafe payloads, and ticking/loop execution markers.

## Hardening Rules

Intervals reject ticking loops, heartbeat, stepped, renderStepped, RunService, timer execution, task handles, timer handles, callbacks, and execution adapters. Intervals are schema values only; they never start loops.
