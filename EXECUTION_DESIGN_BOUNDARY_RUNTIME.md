# Execution Design Boundary Runtime

`ExecutionDesignBoundary` records boundary metadata attached to a design contract.

Fields:

- `boundaryId`
- `contractId`
- `boundaryKind`
- `allowed`
- `summary`
- `tags`
- `metadata`

Boundaries are ledger records only. They do not execute checks, mutate runtime behavior, or apply assets.
