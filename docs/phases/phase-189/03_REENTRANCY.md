# Phase 189 - Reentrancy

An action identity may execute only once at a time. The generation guard marks the action before callback invocation and releases it immediately after protected completion, including callback failure. Recursive or overlapping activation of the same action rejects with a bounded `ReentrantActivation` failure.

Different action identities remain independent.

## Ownership

Phase 189 owns synchronous local action reentrancy protection.

## Non-Ownership

It does not serialize server work, promises, network requests, or gameplay transactions.

## Certification Boundary

Recursive callback failure injection remains a mandatory Studio case.
