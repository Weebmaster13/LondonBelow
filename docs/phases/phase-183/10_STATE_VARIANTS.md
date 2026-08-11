# State Variants

Visual state variants describe presentation posture: Default, Focused,
HoveredIntent, Selected, Disabled, Busy, Loading, Success, Warning, Failure,
Hidden, and Suspended.

These are metadata-only states. The runtime does not listen for input, detect
hovering, mutate focus, animate transitions, or render different visuals.

Variant count is bounded per node. Unsupported states reject before definition
registration.
