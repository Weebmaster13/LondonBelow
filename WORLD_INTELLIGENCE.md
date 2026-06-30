# World Intelligence Specification

Phase 10 defines the reusable spatial intelligence model for London Engine. It gives future systems a shared way to understand what kind of place a player is in before Chapter 1, Monster AI, final scares, or physical world mutation exist.

World Intelligence is not a map loader, scare system, monster system, lighting system, audio system, or gameplay objective system. It is a contract layer that lets those future systems ask safer questions:

- Where is the player?
- What kind of space is this?
- What pressure is fair here?
- Which sounds and lighting changes make sense?
- Can monsters be present, reveal themselves, or begin a chase?
- Should an active puzzle be protected from interruption?
- Is the room safe, hostile, watchful, deceptive, transitional, or puzzle-focused?

## Core Rule

Unknown spaces must be conservative. If a zone has no registered profile, future systems must treat it as `Unknown`, avoid monster reveals, avoid chase starts, avoid blackouts, and avoid major puzzle interruptions.

## Integration Points

Observation Engine should attach `zoneId`, `zoneKind`, and contextual tags to observations when it has reliable information.

Environment Director should use world context to suppress unfair reactions, especially in safe rooms, puzzle rooms, chase routes, and transition spaces.

Future Lighting Director should consume `lightingPolicy` instead of inventing blackout/flicker rules per script.

Future Audio Director should consume `audioPolicy` and atmosphere profiles before playing whispers, fake sounds, silence drops, heartbeat, or breathing.

Future Monster Director should consume `monsterPolicy` and still require DirectorCoordinator approval for reveals, chase starts, and major pressure.

Simulation Framework may register synthetic zone profiles to test policy boundaries without mutating Workspace or creating Chapter 1 content.

## Server Authority

World Intelligence contracts are server-owned. Clients may receive presentation hints later, but clients must not author zone truth, decide whether a chase is allowed, decide whether a puzzle is protected, or approve horror reactions.

## Files

- `src/ServerScriptService/World/WorldTypes.lua`: typed vocabulary for zones, profiles, policies, and affordances.
- `src/ServerScriptService/World/WorldConfig.lua`: conservative defaults for unknown spaces.
- `src/ServerScriptService/World/WorldProfileRegistry.lua`: passive registry for authored profiles.
- `src/ServerScriptService/World/WorldZoneContext.lua`: derives safe context from payload metadata and registered profiles.
- `src/ServerScriptService/World/WorldDiagnostics.lua`: lightweight capture/validation helpers.

## Non-Goals

- No Chapter 1 map.
- No real rooms.
- No Workspace mutation.
- No monster behavior.
- No scares.
- No final art.
- No client remotes.
- No lifecycle service startup yet.

