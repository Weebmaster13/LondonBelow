# Scheduling And Transitions

Scheduling is deterministic and depends only on:

- priority;
- deadline;
- registration order.

Transitions occur only from:

- `EventReceived`
- `QueryEvaluated`
- `CommandAcknowledged`
- `Timeout`
- `ExplicitCancellation`

States are declarative. Execution belongs to runtime consumers behind the messaging architecture, not to the workflow layer.
