# Audio Director Review

The Audio Director was audited for request validation, World Intelligence enforcement, cooldown behavior, diagnostics, and lifecycle cleanup.

## Hardened Behavior

- Invalid explicit `audioKind` values reject instead of falling back to room ambience.
- Unknown zones deny silence drops, major audio pressure, fake sounds, whispers, and unfair puzzle disruption.
- Safe rooms suppress hostile audio pressure.
- Puzzle rooms protect reading, comprehension, and cooperation.
- Fake footsteps and whispers are denied when World Intelligence denies monster presence.
- Observation pressure deltas are clamped.
- Approved decisions use definition-owned cooldowns.
- Deferred and rejected decisions do not create cooldowns.

## Diagnostics

`AudioDirector.inspect()` now exposes:

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

Future Audio Execution must only consume approved Audio Director decisions. It must not play final assets from Director code, bypass World Intelligence, create client-owned fear truth, or turn affordances into automatic sounds.

