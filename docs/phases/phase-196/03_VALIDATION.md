# Phase 196 Validation

## Ownership

Validation rejects non-table input, unknown fields, missing IDs, duplicate components, unsupported component kinds, unsupported render properties, missing parents, cycles, invalid root ownership, and bounded-limit violations.

## Non-Ownership

Validation does not coerce invalid content, silently strip fields, or infer gameplay meaning from component names.

## Certification Boundary

Failed validation happens before rendering mutation. This preserves Phase 185-195 rendering and theming guarantees.
