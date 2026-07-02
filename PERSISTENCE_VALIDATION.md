# Persistence Validation

Persistence validation rejects malformed requests, unsupported schema types, duplicate request ids, duplicate package ids, duplicate migration ids, duplicate policy ids, duplicate failure ids, malformed save/load package schema pairs, malformed migration schemas, malformed write policies, malformed retry policies, malformed failure records, unsafe package payloads, unsafe failure payloads, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized payloads, and deep payloads.

It also rejects client/remote fields, DataStore read/write fields, live persistence/profile loading/cloud save fields, migration execution/save mutation fields, Workspace/gameplay/UI fields, Chapter/story/dialogue/cutscene fields, and anything shaped like live persistence behavior.

## Boundary Rules

- `Save` packages must declare `SavePackageSchema`.
- `Load` packages must declare `LoadPackageSchema`.
- Migration schemas must declare `MigrationSchema` when a schema type is present.
- Write policies must declare `WritePolicySchema` when a schema type is present.
- Retry policies must declare `RetryPolicySchema` when a schema type is present.
- Failure records must declare `FailureRecordSchema` when a schema type is present.

Validation never performs DataStore access, save mutation, migration execution, profile loading, or client authority.
