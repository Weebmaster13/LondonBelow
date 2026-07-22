# Lifecycle And Branching

Conversation lifecycle states:

- Created
- Initialized
- Active
- Waiting
- Transitioning
- Completed
- Closed

Transitions are deterministic and validated by `DialogueStateMachine`.

Branching metadata can reference variables, conditions, and workflow state, but Phase 172 does not execute branching as gameplay. Choice selection records evidence only.
