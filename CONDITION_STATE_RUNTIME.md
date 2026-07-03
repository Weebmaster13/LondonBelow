# Condition State Runtime

Condition state schemas describe possible future condition states. They are not live state and do not mutate gameplay truth.

State records can be used later by governed evaluators, diagnostics, or tooling to understand what states might exist. This runtime never transitions, calculates, or persists those states.

State validation requires a registered condition id, stable state id, state kind, safe payloads, and global namespace uniqueness.
