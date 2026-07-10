# Asset Governance Integration Validation

Validation occurs before mutation. Failed validation records a bounded sanitized failure through the coordinator and never registers schema data.

Validation rejects nil schemas, non-table schemas, invalid ids, unsupported chain kinds, unsupported chain statuses, unsupported node statuses, unsupported reference kinds, unsupported reference statuses, unsupported audit kinds, unsupported audit statuses, duplicate ids across the runtime namespace, missing chain references, duplicate expected order values inside a chain, duplicate runtime names inside a chain, unknown runtime names, unknown provider names, invalid coordinator names, unsafe tags, unsafe metadata, unsafe findings, functions, threads, userdata, Roblox Instance-shaped tables, callbacks, listeners, service handles, runtime handles, asset handles, loaded asset handles, module references, execution adapters, remotes, forbidden execution/client/storage/content markers, excessive depth, excessive node count, oversized strings, excessive tags, excessive audit findings, and excessive chain children.

This phase validates integration metadata only. It does not resolve upstream records and does not require upstream records to exist.
