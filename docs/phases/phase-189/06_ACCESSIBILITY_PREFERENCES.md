# Phase 189 - Accessibility Preferences

The exact preference boundary supports `autoFocusMode` (`Always`, `PreserveOnly`, or `Never`), `announceFocus`, `announceDisabled`, and `announceLiveRegions`. Unknown keys and wrong types reject. Preferences are immutable snapshots, locally configurable, diagnostically visible, and reset on shutdown.

`Always` may select initial/fallback focus, `PreserveOnly` restores only a surviving node, and `Never` performs no programmatic focus assignment.

## Ownership

Phase 189 owns application of local interaction accessibility preferences.

## Non-Ownership

It does not persist settings, create final settings UI, or establish server preference truth.

## Certification Boundary

Every autofocus mode and announcement toggle requires Studio verification.
