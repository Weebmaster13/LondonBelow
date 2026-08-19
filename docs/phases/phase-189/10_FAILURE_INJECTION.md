# Phase 189 - Failure Injection

Required adversarial cases cover stale queued events, recursive actions, unknown actions, callback and announcer exceptions, duplicate modal scopes, invalid initial focus, invalid preferences, rate exhaustion, remount failure, missing focus targets, disabled controls, and shutdown rejection.

Failures are classified, bounded, audit-correlated, and must preserve the last working interaction generation when rejection happens before mutation.

## Ownership

Phase 189 owns the interaction-hardening failure specification.

## Non-Ownership

It does not fabricate injected results or hide failures behind success.

## Certification Boundary

Failure specifications become evidence only when executed authoritatively in Studio.
