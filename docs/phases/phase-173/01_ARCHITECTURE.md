# Architecture

Dialogue Runtime Execution registers after `DialogueCoordinator` and depends on the full messaging, workflow, capability, and domain capability foundation stack.

Execution flow:

1. Load a Phase 172 dialogue definition.
2. Load a Phase 172 conversation instance.
3. Create an execution context.
4. Schedule the execution deterministically.
5. Execute the current node.
6. Traverse validated destinations.
7. Record evidence and diagnostics.

The runtime coordinates conversation progression only.
