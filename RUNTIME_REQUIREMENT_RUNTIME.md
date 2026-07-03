# Runtime Requirement Runtime

Requirements are declarations, not dependency injection.

Requirement records require an existing runtime node and a stable required capability id. They do not resolve dependencies, perform service lookup, trigger initialization, or call any runtime.

Certified requirements reject service lookup payloads, dependency injection payloads, initialization payloads, runtime calls, and service references.
