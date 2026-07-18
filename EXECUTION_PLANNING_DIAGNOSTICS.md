# Execution Planning Diagnostics

Execution Planning diagnostics are health-only and planning-only.

Diagnostics report:

- runtime identity
- initialization and start state
- planning lifecycle state
- graph statistics
- dependency validation status
- constraint validation status
- eligibility summary
- publication status
- blocked runtime truth
- runtime evidence status
- validation failures

Diagnostics never imply Studio execution, Runner invocation, transport creation,
envelope transmission, acknowledgement reception, gameplay mutation, or
certification.

The diagnostics sampler is `executionPlanningRuntime`.
