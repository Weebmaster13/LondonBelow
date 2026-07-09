# Implementation Contract Audit Runtime

`ImplementationContractAudit` describes one review record attached to an implementation contract.

Fields:

- `auditId`
- `contractId`
- `auditKind`
- `reviewer`
- `status`
- `findings`
- `tags`
- `metadata`
- `schemaType`

Audit records are bounded metadata only. They do not approve or perform asset loading, playback, storage mutation, client authority, remotes, gameplay execution, Presentation execution, Save execution, or Chapter content.
