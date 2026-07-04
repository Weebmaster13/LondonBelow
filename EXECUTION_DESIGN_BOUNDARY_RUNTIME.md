# design boundary Runtime

`ExecutionDesignBoundary` records requirement metadata attached to a design contract.

Fields:

- `boundaryId`
- `contractId`
- `requirementKind`
- `required`
- `satisfied`
- `summary`
- `tags`
- `metadata`

Requirements are ledger records only. They do not execute checks, mutate runtime behavior, or apply assets.
