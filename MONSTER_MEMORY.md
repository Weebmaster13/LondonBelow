# Monster Memory

Monster memory stores what a monster remembers experiencing. Memory is not knowledge and is not objective truth.

## Remembered Data

Monsters may remember last seen player, last heard player, last known room, opened doors, closed doors, broken objects, recent puzzles, light sources, lantern usage, safe rooms, player habits, investigation failures, false leads, and confidence.

## Decay

Memory confidence decays over time. Low-confidence and expired memories are removed. This allows monsters to search, hesitate, or become wrong without holding perfect omniscience.

## Safety

Memory is bounded per monster. Entries are cloned for inspection. Invalid confidence, invalid kind, negative age, and unknown monster ids reject.

## Future Use

Monster AI may later use memory through approved intent. It must not create memory directly from client truth or bypass Observation Engine.
