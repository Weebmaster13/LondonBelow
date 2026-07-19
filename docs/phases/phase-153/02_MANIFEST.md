# Manifest

The framework generates the execution manifest before evidence import.

The manifest records:

- session ID
- phase
- backend
- targets
- policies
- environment
- capabilities
- evidence categories
- artifact plan

Phase 153 evidence is written to `automation/runtime-evidence/phase-153` after the implementation commit so it can bind to a clean source state.
