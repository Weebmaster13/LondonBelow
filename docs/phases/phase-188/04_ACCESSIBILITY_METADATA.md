# Phase 188 - Accessibility Metadata

Allowed fields are `role`, `label`, `description`, `focusable`, `actionId`, `disabled`, and `selectionOrder`. Unknown fields reject. Text is non-empty and bounded. Interactive buttons require labels and `focusable=true`; action identities are allowed only on TextButton or ImageButton. Boolean and integer fields are exact.

Validated values are copied to London Engine attributes for inspection. Focus announcements combine label and description through an optional local announcer callback.

## Ownership

Phase 188 owns validation and execution of contract accessibility metadata.

## Non-Ownership

It does not claim to be a full screen reader, localization engine, speech system, or final accessibility settings UI.

## Certification Boundary

Metadata compliance is Candidate evidence, not universal accessibility certification.
