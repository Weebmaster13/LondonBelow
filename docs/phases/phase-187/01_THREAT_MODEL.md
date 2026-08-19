# Phase 187 - Threat Model

The hardened boundary rejects unknown fields, malformed metadata, multiple PlayerGui roots, stale revisions, detached owned nodes, changed ownership attributes, and unexpected tree cardinality.

## Ownership

Phase 187 owns fail-closed client rendering invariants.

## Non-Ownership

It does not treat client state as trusted server evidence.

## Certification Boundary

Threat-model coverage is necessary but insufficient for Studio certification.
