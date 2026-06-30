# Lighting Director Review

The Lighting Director was audited for request validation, World Intelligence enforcement, cooldown behavior, diagnostics, and lifecycle cleanup.

## Hardened Behavior

- Invalid explicit `lightingKind` values reject instead of falling back to dimming.
- Unknown zones deny shadow pressure, visibility pressure, chase-support lighting, blackout-capable pressure, and unfair puzzle disruption.
- Safe rooms suppress hostile lighting pressure.
- Puzzle rooms protect comprehension and cooperation.
- Observation pressure deltas are clamped.
- Approved decisions use definition-owned cooldowns.
- Deferred and rejected decisions do not create cooldowns.

## Diagnostics

`LightingDirector.inspect()` now exposes:

- recent decisions
- suppression reasons
- policy suppressions
- safe-room suppressions
- puzzle suppressions
- cooldown count
- cooldown creation count
- pressure state and score
- World policy safety summary
- health

## Future Execution Boundary

Future Lighting Execution must only consume approved Lighting Director decisions. It must not perform blackouts in unknown zones, mutate Lighting from Director code, bypass Governance, or create client-owned truth.

