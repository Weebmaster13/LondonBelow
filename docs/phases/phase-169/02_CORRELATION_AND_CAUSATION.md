# Correlation And Causation

`WorkflowCorrelation` owns bounded correlation records keyed by `correlationId`.

Each record captures:

- `correlationId`;
- `causationId`;
- `workflowId`;
- `instanceId`;
- `rootWorkflowId`;
- `parentWorkflowId`;
- `sourceKind`;
- `sourceId`;
- metadata.

`WorkflowCausation` owns ordered causation records. Records preserve message kind, correlation id, instance id, source runtime, target runtime, parent causation id, and bounded metadata.

Duplicate correlations reject before workflow activation mutates additional state.
