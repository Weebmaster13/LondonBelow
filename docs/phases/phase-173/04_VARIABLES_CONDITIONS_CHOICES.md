# Variables, Conditions, And Choices

Runtime variables are scoped to one execution context.

Variable mutation records old value, new value, node id, and execution evidence. Variable mutation never affects unrelated conversations or other capabilities.

Conditions evaluate metadata and runtime variables without mutating state.

Choices validate the current node, selected choice id, and destination node. Every accepted choice records evidence.
