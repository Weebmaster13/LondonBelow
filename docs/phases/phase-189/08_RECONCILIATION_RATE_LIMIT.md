# Phase 189 - Reconciliation Rate Limit

A monotonic one-second budget allows at most 120 interaction reconciliations. The renderer must acquire a one-use interaction permit after contract validation but before Instance staging or root commit. Excess work therefore rejects before any visual mutation. Staging or commit failure cancels the pending permit; reconciliation consumes only the exact current permit. Diagnostics expose used, rejected, limit, and window identity. Shutdown resets the budget and permit state.

## Ownership

Phase 189 owns client interaction reconciliation flood protection.

## Non-Ownership

It does not throttle server gameplay, network traffic, rendering frame rate, or unrelated UI.

## Certification Boundary

Boundary and recovery behavior require deterministic Studio stress evidence.
