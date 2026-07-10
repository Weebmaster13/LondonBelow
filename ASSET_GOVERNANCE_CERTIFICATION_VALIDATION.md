# Asset Governance Certification Validation

Validation occurs before mutation. Failed validation records a bounded sanitized failure and never registers schema data.

Validation rejects nil schemas, non-table schemas, invalid ids, duplicate ids, missing certification references, unsupported certification kinds/statuses, unsupported requirement kinds/statuses, unsupported result kinds/statuses, unsupported audit kinds/statuses, unsafe metadata, unsafe findings, unsafe evidence, unsafe tags, functions, threads, userdata, Instance-shaped tables, runtime handles, asset handles, loaded assets, module references, execution adapters, callbacks, listeners, services, cycles, oversized payloads, deep payloads, oversized strings, and forbidden execution markers.

Certification metadata does not authorize execution and does not mutate upstream runtimes.
