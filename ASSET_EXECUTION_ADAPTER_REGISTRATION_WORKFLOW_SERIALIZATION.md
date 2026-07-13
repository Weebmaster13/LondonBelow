# Asset Execution Adapter Registration Workflow Serialization

Serialization exposes copied metadata only and performs deep-copy isolation.

Serializable payloads may contain bounded strings, numbers, booleans, arrays, and plain tables. Serialization rejects functions, threads, userdata, metatables, instance-shaped tables, cycles, unsafe keys, oversized strings, oversized payload depth, oversized payload node counts, and forbidden runtime markers.

Serialization never exposes adapter implementations, workflow handles, registry handles, runtime handles, dispatcher handles, scheduler handles, execution references, activation references, mutable references, gameplay references, Presentation references, Save references, or Chapter references.