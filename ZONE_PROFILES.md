# Zone Profiles

Zone profiles are server-authored contracts that describe what future systems may do in a space. They are not map instances and do not create Workspace content.

## Required Fields

- `id`: stable unique zone id.
- `kind`: district, street, building, floor, wing, room, micro-zone, safe room, puzzle room, chase route, exterior, interior, transition, or unknown.
- `displayName`: human-readable developer label.
- `parentId`: optional parent zone.
- `atmosphereProfileId`: reference to reusable atmosphere behavior.
- `roomPersonalityId`: reference to reusable room personality.
- `affordances`: explicit list of allowed environmental affordances.
- `lightingPolicy`: allowed brightness, blackout, flicker, and misdirection behavior.
- `audioPolicy`: allowed whisper, fake sound, heartbeat, breathing, silence, and sound tags.
- `monsterPolicy`: whether presence, reveal, crawlers, and chase are allowed.
- `puzzleProtection`: how pressure behaves around puzzle work.
- `tags`: searchable developer tags.

## Safe Rooms

Safe rooms must suppress chase starts, main monster reveals, crawler pressure, major lighting attacks, and unfair fake sounds. They may allow low ambience, soft silence, or distant pressure if the Horror Director approves it.

Safe rooms should help players breathe without making the game feel disconnected from the building.

## Puzzle Rooms

Puzzle rooms should protect comprehension and fairness. They may allow subtle pressure, whispers, heartbeat, lantern instability, and environmental attention, but major interruptions must be opt-in and Director-approved.

Puzzle rooms should never be punished simply because a player is reading, thinking, or coordinating with teammates.

## Chase Routes

Chase routes define where future chase pressure can begin or continue. They should be readable, multiplayer-safe, and free of unfair dead ends unless the encounter is explicitly authored around that risk.

Chase routes do not create Monster AI. They only tell future Monster Director and movement systems that chase behavior is allowed there.

## Exterior and Interior Zones

Exterior zones usually allow fog, rain muffling, gaslight ambience, distant carriage sounds, and street-level pressure.

Interior zones usually allow room pressure, floor creaks, door reactions, light dimming, breathing, whispers, and building intelligence.

## Transition Zones

Transition zones are thresholds such as doors, stairwells, carriage steps, elevators, gates, or loading-adjacent corridors. They should be treated carefully because players may be reorienting, teleporting, or joining teammates.

