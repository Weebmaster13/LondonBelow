# Governance Runtime Node Runtime

`GovernanceRuntimeNode` records describe one certified runtime position inside a governance chain.

Required fields are `nodeId`, `chainId`, `runtimeName`, `providerName`, `coordinatorName`, `expectedOrder`, `required`, and `nodeStatus`.

Runtime nodes validate against the certified provider order, but they do not require or mutate upstream runtime records in Phase 59.
