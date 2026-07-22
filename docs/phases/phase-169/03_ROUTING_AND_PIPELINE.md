# Routing And Pipeline

`WorkflowRouting` validates workflow messages and routes them only when their `correlationId` exists and matches the target workflow instance.

Supported message kinds are:

- `CommandIntent`;
- `CommandAcknowledgement`;
- `EventObservation`;
- `QueryEvaluation`;
- `TimeoutSignal`.

`WorkflowExecutionPipeline` records ordered execution stages. It stores activation, routing, transition, suspension, resumption, completion validation, and completion evidence. The pipeline is observational and does not execute command handlers, publish events, or perform queries.
