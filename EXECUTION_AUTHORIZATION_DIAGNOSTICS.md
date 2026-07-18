# Execution Authorization Diagnostics

Execution Authorization diagnostics are metadata-only.

Diagnostics report:

- runtime identity
- lifecycle state
- loaded policy count
- loaded rule count
- evaluation status
- decision summary
- blocked runtime truth
- publication state
- runtime evidence state
- validation failures

Diagnostics never imply Studio execution, Runner invocation, scheduling,
transport creation, envelope transmission, acknowledgement reception, runtime
evidence, gameplay mutation, or certification.

The diagnostics sampler is `executionAuthorizationRuntime`.
