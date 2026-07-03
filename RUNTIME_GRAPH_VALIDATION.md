# Runtime Graph Validation

Validation rejects malformed ids, duplicate ids across the global Runtime Graph namespace, unsupported schema types, unsupported runtime layers, unsupported dependency, ordering, and compatibility kinds, missing endpoints, self-dependencies, direct required cycles, self-ordering, direct ordering contradictions, unsafe metadata, unsafe context, unsafe tags, Roblox Instances, functions, threads, userdata, cycles, oversized strings, oversized payloads, deep payloads, and forbidden execution/lifecycle/service/client/content fields.

Forbidden fields reject in metadata, context, tags, nested tables, table keys, and string values.
