# Lifecycle Transition Runtime

Transitions are allowed-transition descriptions, not state changes.

Transition records describe from-state, to-state, transition kind, policy ids, guard ids, and reason. They do not mutate lifecycle state, call runtime APIs, call Framework, or execute startup/shutdown behavior.

## Hardening Rules

Transitions reject unsupported from/to states, unsupported transition kinds, identical non-future transitions, invalid policy references, invalid guard references, startup execution payloads, shutdown execution payloads, lifecycle mutation payloads, runtime API payloads, and live service payloads. They are allowed-transition descriptions only; they never move a runtime between states.
