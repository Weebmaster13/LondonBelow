# Monster Behavior Intelligence

Phase 15 behavior modules are scoring models, not behavior trees and not movement.

## Models

- `InterestModel`: scores noise, movement, light, identity, memories, doors, Journal activity, hesitation, group separation, and objectives.
- `ThreatModel`: measures pressure relevance, not aggression.
- `CuriosityModel`: reacts to novelty such as new noises, opened doors, missing memories, missing objects, and unexpected behavior.
- `PatienceModel`: controls watching, waiting, giving up, and returning potential.
- `SearchModel`: scores stale-but-useful remembered information.
- `TerritoryModel`: helps future monsters care about areas without owning navigation.
- `InvestigationModel`: blends interest, curiosity, and patience.

## Rule

These models produce scores and reasons only. They never chase, attack, move, animate, spawn, or mutate the world.

## Future Use

Future archetypes can reinterpret scores differently. One monster may investigate high curiosity; another may wait with high patience. The intent layer remains separate from physical execution.
