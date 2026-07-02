# Accessibility Runtime

Phase 32 defines the Accessibility Runtime Foundation for London Engine.

This runtime is server-authoritative schema infrastructure for future accessibility settings, visual safety rules, audio safety rules, input assist schemas, motion comfort schemas, readability schemas, and content warning schemas.

It records accessibility structure only. It does not execute settings or create final UI.

## Owns

- Accessibility setting schemas
- Visual safety rule schemas
- Audio safety rule schemas
- Input assist schemas
- Motion comfort schemas
- Readability schemas
- Content warning schemas
- Validation
- Serialization
- Diagnostics
- Snapshots
- Deterministic self-checks
- Shutdown cleanup

## Does Not Own

- Final accessibility UI
- Client settings execution
- Input remapping execution
- Audio execution
- Lighting execution
- Camera execution
- VFX execution
- Workspace mutation
- Remotes
- Client authority
- Gameplay execution
- Chapter content

Future accessibility presentation and client-side application must be implemented separately as server-approved presentation, never as client-owned truth.
