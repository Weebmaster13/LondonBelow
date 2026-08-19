# Phase 188 - Studio Test Matrix

The structured importer requires fourteen named passing cases: mouse, touch, keyboard, gamepad, disabled, unknown-action, callback-failure, focus-first-mount, focus-revision-restore, focus-missing-fallback, unmount-cleanup, shutdown-cleanup, multiplayer-isolation, and low-end-budget.

Evidence must use schema version 1, exact Phase 188, `RobloxStudio` environment, authoritative and passed flags, a non-empty run ID, and all required test identities. Missing, malformed, partial, or failed evidence remains blocked.

## Ownership

Phase 188 owns the test contract and strict evidence acceptance rules.

## Non-Ownership

It does not manufacture Studio execution or infer passes from static source.

## Certification Boundary

All fourteen required cases must be present and passing for evidence acceptance.
