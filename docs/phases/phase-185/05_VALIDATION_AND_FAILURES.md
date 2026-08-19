# Phase 185 - Validation and Failures

Validation rejects malformed or non-serializable data, version drift, unknown fields, missing fields, duplicate IDs, unknown/forbidden classes, illegal properties, wrong value kinds, invalid parent references, hierarchy cycles, excessive depth, and budget overflow. Failures are stable, bounded, diagnostic, and audit-correlated.

## Ownership

Phase 185 owns contract validity decisions and stable failure classification.

## Non-Ownership

It does not silently coerce, strip, repair, render, or retry invalid contracts.

## Certification Boundary

Failure coverage supports Production Candidate status only.
