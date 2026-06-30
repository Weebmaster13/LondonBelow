# London Engine Observation Engine

The Observation Engine is the server-authoritative sensory nervous system of London Below. It is not analytics, telemetry, debugging, or an event logger. It turns trusted gameplay facts into validated, enriched, remembered observations that downstream systems can interpret.

The golden rule is simple: gameplay systems report observations to the Observation Engine first. The Horror Director, future Monster AI, story systems, and presentation bridges consume processed knowledge later.

## Architecture

`ServerScriptService/Horror/Observation` contains the Phase 4 runtime:

- `ObservationService.lua`: lifecycle owner, observation intake, routing, enrichment, forwarding, diagnostics, and cleanup.
- `ObservationTypes.lua`: shared Luau contracts for definitions, inputs, accepted observations, context, patterns, timelines, and inspection.
- `ObservationConfig.lua`: safe limits for metadata, memory, profiling, and pattern thresholds.
- `ObservationRegistry.lua`: canonical observation IDs and metadata. Future systems import IDs from here instead of inventing magic strings.
- `ObservationValidator.lua`: rejects malformed IDs, unknown types, impossible timestamps, oversized metadata, invalid players, and corrupted payloads.
- `ObservationAggregator.lua`: compact counts by observation ID, category, user, and high-priority recent observations.
- `ObservationMemory.lua`: bounded immediate, 10 second, 30 second, 1 minute, 5 minute, 10 minute, chapter, and match memory windows.
- `ObservationPatternRecognizer.lua`: turns repeated facts into behavior patterns and evolving personality confidence scores.
- `ObservationContext.lua`: injects known chapter, room, area, weather, lighting, objective, puzzle, proximity, tag, and tension context.
- `ObservationTimeline.lua`: queryable player, party, chapter, monster, and environment timelines.
- `ObservationSignals.lua`: internal EventBus signal names.
- `ObservationDiagnostics.lua`: read-only diagnostics and validation aggregation.
- `ObservationProfiler.lua`: engine health counters for accepted, rejected, and slow observations.

## Observation Flow

1. A trusted server gameplay system calls `ObservationService.observe()` or publishes `Observation.Submitted`.
2. `ObservationValidator` checks the payload and registry definition.
3. `ObservationContext` enriches the observation from metadata and current server context.
4. `ObservationAggregator`, `ObservationMemory`, and `ObservationTimeline` record the accepted fact.
5. `ObservationPatternRecognizer` updates patterns and personality confidence.
6. `ObservationService` publishes accepted observation and pattern signals.
7. If a registry definition has a Director mapping, the service forwards a compatible observation to `HorrorDirector.Observation`.

The Director receives enriched, validated knowledge. It should not be the first stop for raw facts.

## Validation

The engine rejects unsafe observations:

- Missing, malformed, or unknown observation IDs.
- Player references that are not active `Player` instances in the current server.
- NaN, impossible, stale, or far-future timestamps.
- Non-numeric or oversized amounts.
- Metadata with too many keys, invalid keys, unsupported value types, excessive nesting, or huge strings.
- Registry definitions with duplicate IDs, invalid weights, bad priorities, or invalid definitions.

This validation is intentionally strict. If a future system cannot pass validation, fix the reporting contract instead of weakening server authority.

## Registry Rules

Every observation type lives in `ObservationRegistry.lua`. IDs use stable namespaced strings such as:

- `Movement.StartSprint`
- `Camera.LookBehind`
- `Interaction.OpenDoor`
- `Puzzle.Progress`
- `Lantern.Flicker`
- `Environment.EnterDarkness`
- `Monster.Sighted`
- `Social.PartySeparated`
- `Exploration.EnterRoom`
- `Story.ObjectiveCompleted`
- `Time.SafeTooLong`

Each definition includes category, description, expected metadata, weight, priority, aggregation rule, expiration window, and optional Horror Director compatibility mapping.

## Context Engine

Observations should not arrive as isolated facts. The context layer can attach:

- Current chapter and phase.
- Room, area, and building zone.
- Weather and lighting.
- Objective and puzzle IDs.
- Nearby player and monster counts.
- Time since last scare and current tension state.
- Area and room tags.

Example: `Interaction.OpenDoor` is more meaningful when enriched with “while alone,” “inside the east wing,” “after four minutes of silence,” and “during heavy rain.”

## Memory And Timeline

Memory is run-local and bounded. It is not save data.

The engine keeps windows for immediate, 10 seconds, 30 seconds, 1 minute, 5 minutes, 10 minutes, chapter, and match. It also tracks compact counters for routes, rooms, door usage, hiding spots, scare IDs, monster sightings, puzzle attempts, lantern usage, darkness exposure, and investigation behavior.

The timeline can answer questions such as:

- What happened to this player recently?
- What happened in the last three minutes?
- Which monster observations happened this match?
- Which environment events were high-priority?

## Pattern Recognition

Patterns are not labels of who a player “is.” They are temporary interpretations of repeated behavior.

Current foundation patterns include:

- Repeated look-behind behavior.
- Comfort entering darkness.
- Door hesitation.
- Room looping.
- Window watching.
- Frequent party separation.
- Objective rushing.

Personality confidence can evolve across traits such as Explorer, Investigator, Survivor, LoneWolf, Follower, RiskTaker, Observer, Paranoid, Methodical, Impulsive, Fearful, Curious, Reserved, Adaptive, Persistent, and Patient. Scores decay over time and can combine.

## Horror Director Integration

The Observation Engine owns truth. The Horror Director owns interpretation.

Some registry definitions map to existing Director observation kinds for compatibility:

- `Movement.StartSprint` -> `Sprint`
- `Camera.LookBehind` -> `LookBehind`
- `Interaction.DoorHesitation` -> `DoorHesitation`
- `Puzzle.Progress` -> `PuzzleProgress`
- `Lantern.On` -> `LanternUse`
- `Environment.EnterDarkness` -> `Darkness`
- `Monster.Sighted` -> `ScareSeen`
- `Monster.ChaseStarted` -> `ChaseSeen`
- `Social.PartySeparated` -> `TimeAlone`
- `Social.Regrouped` -> `TimeWithParty`
- `Exploration.ReturnRoom` -> `RepeatedRoute`
- `Story.ObjectiveCompleted` -> `ObjectiveProgress`

Future Director work should consume Observation Engine summaries directly instead of expanding direct Director intake.

## Future Monster AI Integration

Monster AI should consume Observation Engine timelines, patterns, and selected Director decisions. It should not receive raw gameplay facts directly from unrelated systems.

Future Monster AI may use:

- Player route repetition.
- Hiding spot memory.
- Party separation.
- Window watching and look-behind patterns.
- Monster sighting and chase timelines.
- Director-approved opportunity windows.

Monster AI still owns movement, perception, pathfinding, attacks, and physical execution.

## Examples

Trusted server gameplay code:

```lua
ObservationService.observe({
	id = "Interaction.OpenDoor",
	player = player,
	source = "DoorService",
	metadata = {
		doorId = "manor_foyer_north",
		roomId = "manor.foyer",
		buildingZone = "main_building",
	},
})
```

Server systems may also publish:

```lua
EventBus.publishDeferred(ObservationSignals.Submitted, {
	id = "Camera.LookBehind",
	player = player,
	source = "CameraIntentService",
	metadata = {
		roomId = "manor.hallway.east",
	},
})
```

Do not let clients submit these directly. A client may request an action; the server validates the action and then emits the observation.

## Future Extensions

Planned expansion points:

- Chapter-specific observation packs.
- Stronger spatial context from room volumes and zone binders.
- Party-level pattern summaries.
- Monster-specific timelines.
- Weather and building intelligence feeds.
- Observation query APIs for Horror Director v2.
- Test harnesses for deterministic multi-player observation sequences.
- Optional analytics export after privacy and product requirements are defined.

## Current Limits

This phase creates the engine foundation only. It does not implement chapter gameplay, Monster AI, final UI, final art, or analytics export. Some observations are compatibility mappings for systems that will be built later.
