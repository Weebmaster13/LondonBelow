# Schedule Interval Runtime

Intervals are schema values, not ticking loops.

Interval records describe interval policy values for future scheduler design. They do not create loops, tick callbacks, RunService hooks, or frame updates.

Intervals reject malformed ids, unsafe payloads, and ticking/loop execution markers.
