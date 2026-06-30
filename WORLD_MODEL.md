# World Model

The London Engine world model is hierarchical. Future chapters should describe authored spaces from broad to specific:

1. District
2. Street
3. Building
4. Floor
5. Wing
6. Room
7. Micro-zone

Each layer may own descriptive metadata, but moment-to-moment gameplay should resolve to the most specific known zone. A hiding alcove inside a puzzle room can be a micro-zone while still inheriting the room's puzzle protection.

## Districts

Districts describe broad London areas such as a fog-drowned street network, institutional grounds, or a river-adjacent quarter. Districts help future directors understand global weather, ambient identity, and travel context.

Districts should not contain direct puzzle logic, monster logic, or scare logic.

## Streets

Streets describe exterior navigation spaces. They commonly allow fog, rain muffling, gaslight effects, distant sounds, and low-intensity environmental pressure.

Street profiles should state whether they are safe traversal, lobby-adjacent, chase-capable, or protected narrative routes.

## Buildings

Buildings represent major authored structures. London Below's main building should be modeled as a building profile with wings, floors, and rooms beneath it. Building-level intelligence may express that the building is watchful, oppressive, deceptive, or protective.

Buildings do not own Horror Director pacing. They provide context.

## Floors and Wings

Floors and wings organize route logic and atmosphere. Future systems may use them to understand whether players are split, whether sounds should bleed between spaces, and whether pressure should rise as players move deeper.

## Rooms

Rooms carry the strongest gameplay context. A room can be safe, puzzle-focused, hostile, deceptive, transitional, or chase-capable.

Every room profile should answer:

- Is this a safe room?
- Is this a puzzle room?
- Is this part of a chase route?
- Is it interior or exterior?
- What lighting is allowed?
- What sound behavior is allowed?
- Are monsters allowed to appear?
- Should puzzle focus be protected?

## Micro-Zones

Micro-zones describe specific subareas such as hiding spots, doorway thresholds, windows, stair turns, carriage boarding zones, puzzle panels, or narrow corners.

Micro-zones should refine behavior without becoming isolated gameplay systems. A micro-zone may say "door reactions are allowed here" or "chase continuation is allowed here"; it should not decide to trigger a scare by itself.

## Context Payloads

Future observations should prefer this shape:

```lua
{
	metadata = {
		zoneId = "chapter1.main_building.floor1.west_hall",
		zoneKind = "Room",
		tags = { "Interior", "Gaslit", "PuzzleAdjacent" },
	},
}
```

If `zoneId` is known, `WorldZoneContext` resolves the registered profile. If not, it returns conservative unknown defaults.

