# Execution Authorization Validation

Phase 149 validation is exact-schema and deterministic.

## Policies

Policies require:

- `policyId`
- `policyKind`
- `policyVersion`
- `required`
- `ruleIds`
- `metadata`

Validation rejects unknown policies, duplicate policy ids, unsupported policy
kinds, version drift, unsafe metadata, malformed rule references, and over-limit
policy sets.

## Rules

Rules require:

- `ruleId`
- `policyId`
- `ruleKind`
- `expected`
- `metadata`

Validation rejects duplicate rules, unknown policy references, unsupported rule
kinds, unsafe payloads, and over-limit rule sets.

## Planning Input

Authorization rejects missing planning publications, unpublished planning
records, planning version drift, and blocked runtime truth drift.

## Decisions

Published decisions reject unsupported decision states, invalid authorization
classifications, mutable publication state, runtime truth drift, and malformed
evaluated rule arrays.
