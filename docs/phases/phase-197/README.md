# Phase 197 - Blackwater Descent World, Art, Atmosphere, and Exploration Production

## Baseline

Phase 197 extends the Phase 196 Blackwater Descent vertical slice from a compact traversable test map into a room-authored production layout. The baseline commit is `4af4fb5bb1f1afd4a03d42dc7115486101b4d44a`.

## Ownership

Owned by `Chapter196VerticalSliceCoordinator`, `BlackwaterProductionConfig`, `BlackwaterEnvironmentProductionRuntime`, and `Chapter196WorldBuilder`.

## Non-Ownership

This phase does not create final art assets, asset loading, remotes, persistence, analytics, telemetry, Monster AI authority, or Chapter 1 content.

## Implementation

The production config defines fifteen authored rooms: Victorian street, front steps, foyer, west wing, east wing, upper gallery, constable room, servants' corridor, kitchen, cellar, crypt access, ward chambers, forbidden archive, ritual chamber, and escape route. Each room declares a story purpose, mechanic purpose, safety role, and spatial dimensions. The world builder consumes this table and creates deterministic runtime-owned geometry with `StoryPurpose`, `MechanicPurpose`, `SafeSpace`, and reactive-state attributes.

Exploration now includes a critical path, optional evidence rooms, three shortcut declarations, safe regroup spaces, risky detours, chase-loop affordances, and authored landmarks. Environmental state advances through arrival, investigation, ward puzzle, Bailiff awakening, archive opening, blackout, escape, and dawn aftermath.

## Validation

`london:phase197:selfcheck` verifies room count, shortcut count, environment-stage publication, asset-manifest honesty, production-config consumption, and forbidden runtime surfaces.

## Certification Boundary

Production Candidate only. Studio navigation, art review, performance measurement, and human playtest evidence are still required before certification.

## Known Limitations

Runtime-authored geometry is production-structured but not final art. The asset manifest marks final bespoke modeling as outstanding.

## Next Handoff

Phase 198 uses the room graph and pressure stages to introduce The Bailiff without replacing the world owner.
