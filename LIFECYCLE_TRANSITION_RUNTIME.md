# Lifecycle Transition Runtime

Transitions are allowed-transition descriptions, not state changes.

Transition records describe from-state, to-state, transition kind, policy ids, guard ids, and reason. They do not mutate lifecycle state, call runtime APIs, call Framework, or execute startup/shutdown behavior.
