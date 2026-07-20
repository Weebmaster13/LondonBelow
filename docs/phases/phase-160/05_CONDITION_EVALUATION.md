# Condition Evaluation

Completion conditions can depend on existing runtime facts:

- interaction completed
- environmental state
- inspection completed
- binary mechanism state
- presentation acknowledgement metadata
- runtime event
- objective completed

Evaluation is deterministic for identical accepted events. Conditions do not read UI state and do not trust client-owned state.
