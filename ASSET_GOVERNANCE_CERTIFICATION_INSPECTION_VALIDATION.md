# Asset Governance Certification Inspection Validation

Validation rejects nil and non-table schemas, invalid ids, unsupported enum values, duplicate ids, invalid runtime names, invalid provider names, invalid snapshot providers, missing inspection references, missing observation references, missing finding references, unsafe metadata, unsafe evidence, unsafe findings, cycles, oversized strings, deep payloads, and oversized node counts.

Validation always occurs before mutation. Failed validation records a sanitized validation failure and never stores the rejected schema.

Provider validation requires the provider and snapshot provider to match the declared runtime in the certified governance order. This runtime accepts copied metadata only; it never resolves live subsystem references.
