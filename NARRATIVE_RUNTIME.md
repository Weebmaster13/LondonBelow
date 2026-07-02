# Narrative Runtime

Phase 19 creates the server-authoritative Narrative Runtime foundation for London Engine.

This is not final story writing, Chapter content, cutscenes, final dialogue, final UI, or presentation. It is a schema and eligibility layer that future Chapter 0 and Chapter 1 work can build on safely.

## Owns

- Narrative beat schema state.
- Story gate schema state.
- Reveal eligibility state.
- Emotional beat protection state.
- Links to future Journal, Memory Fragment, and Identity schemas.
- Diagnostics, snapshots, validation, serialization, and self-checks.

## Does Not Own

- Final story prose.
- Final dialogue.
- Chapter content.
- Cutscenes.
- UI.
- Client-owned narrative truth.
- Workspace mutation.
- Audio or Lighting execution.
- Monster AI.
- Horror pacing.

## Runtime Location

The implementation lives in `src/ServerScriptService/Narrative/Core` and is registered as `NarrativeCoordinator`.