# Phase 189 - Live Regions

Metadata adds `liveRegion` with exact values `Off`, `Polite`, and `Assertive`. During reconciliation, non-Off regions emit label/description content through the optional local announcer with explicit priority context when live-region announcements are enabled.

The runtime contains announcer exceptions and does not claim speech or screen-reader implementation.

## Ownership

Phase 189 owns local live-region announcement intent and priority metadata.

## Non-Ownership

It does not own text-to-speech, localization, Roblox platform accessibility, or external assistive technology.

## Certification Boundary

Polite/assertive ordering and disabled preference behavior require Studio evidence.
