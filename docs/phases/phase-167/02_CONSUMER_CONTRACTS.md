# Consumer Contracts

Every runtime consumer registers an immutable contract with:

- `consumerId`
- `ownerRuntime`
- `version`
- `capabilities`
- `subscriptions`
- `publicInterfaces`
- `requiredInterfaces`
- `lifecycle`
- `dependencies`
- `authorityLevel`
- `supportedCommands`
- `supportedEvents`
- `supportedQueries`

Unknown fields, missing fields, duplicate consumers, unsupported authority levels, malformed arrays, unsafe payload fields, and oversized payloads reject before mutation.

Contracts describe how a runtime participates in messaging. They do not grant command execution, event publication, query execution, gameplay authority, networking, persistence, Workspace mutation, or client authority.
