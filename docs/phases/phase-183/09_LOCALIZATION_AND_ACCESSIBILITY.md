# Localization And Accessibility

Text nodes reference localization slots and token IDs. The runtime validates
identifier shape but does not resolve translated strings.

Accessibility metadata can include screen reader tokens, alternate text tokens,
focus intent, reading intent, reduced-motion sensitivity, flashing-risk
metadata, and text-scaling posture. Phase 183 validates metadata shape and
preserves it in resolved plans.

No accessibility rendering, focus handling, input capture, voice playback, or
client UI behavior is implemented in this phase.
