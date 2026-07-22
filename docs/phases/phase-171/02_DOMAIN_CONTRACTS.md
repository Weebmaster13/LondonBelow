# Domain Contracts

Domain capability definitions use exact schema validation.

Required fields:

- capabilityId
- domain
- version
- owner
- interfaces
- dependencies
- authority
- workflowParticipation
- healthProvider
- diagnosticsProvider
- snapshotProvider
- metadata

Unknown fields, missing fields, unsupported domains, unsupported authority values, unsupported workflow participation, duplicate interfaces, unsafe payload markers, oversized payloads, deep payloads, functions, threads, userdata, and Roblox Instances reject before mutation.
