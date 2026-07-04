# design responsibility Runtime

`ExecutionDesignResponsibility` records risk metadata attached to a design contract.

Fields:

- `responsibilityId`
- `contractId`
- `riskKind`
- `severity`
- `summary`
- `mitigated`
- `tags`
- `metadata`

Risks are evidence metadata only. They do not evaluate runtime behavior or mutate assets.
