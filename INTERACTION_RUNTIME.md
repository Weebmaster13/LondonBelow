# Interaction Runtime

Phase 23 creates the server-authoritative Interaction Runtime Foundation for London Engine.

This runtime defines how future interactable objects are represented before any actual gameplay interaction exists. It is a schema substrate for doors, drawers, switches, valves, handles, locks, keyholes, inspectable objects, readable objects, pickupable object schemas, hiding spot schemas, and puzzle interactable schemas.

It does not open doors, move drawers, pick up items, create prompts, play audio, run animations, change lighting, mutate Workspace, create remotes, or accept client authority.

## Architecture Position

Interaction Runtime sits above Physical Runtime and below future gameplay systems:

Physical Runtime -> Interaction Runtime -> future Gameplay Execution Bridge requests -> future Physical/Presentation adapters.

Phase 23 may reference `physicalObjectId` values owned by Physical Runtime, but it does not mutate Physical Runtime. It may record future intent schemas that describe possible Gameplay Execution Bridge requests, but it does not submit execution. It may reference future Presentation Runtime intent, but it does not create UI prompts or client presentation.

## Owns

- interaction object schemas
- interaction eligibility schemas
- interaction intent records
- interaction locks
- cooldown schemas
- diagnostics
- snapshots
- serialization
- validation
- deterministic self-checks
- shutdown cleanup

## Does Not Own

- actual door opening
- actual drawer movement
- item pickup execution
- inventory ownership
- animation
- audio
- UI prompts
- camera
- lighting
- Workspace mutation
- physics
- pathfinding
- Monster AI
- Narrative
- Save
- Horror pacing
- Chapter content
- dialogue
- story
- client authority
- remotes

## Supported Schema Types

- `DoorInteractionSchema`
- `DrawerInteractionSchema`
- `SwitchInteractionSchema`
- `ValveInteractionSchema`
- `HandleInteractionSchema`
- `LockInteractionSchema`
- `KeyholeInteractionSchema`
- `InspectableInteractionSchema`
- `ReadableInteractionSchema`
- `PickupableInteractionSchema`
- `HidingSpotInteractionSchema`
- `PuzzleInteractionSchema`
- `SystemInteractionSchema`

These names identify schema categories only. They do not implement final behavior.

## Required Schema Fields

Every interaction schema must include:

- `interactionId`
- `physicalObjectId`
- `interactionType`
- `ownerSystem`
- `eligibility`
- `requiredState`
- `cooldown`
- `lockState`
- `metadata`
- `context`
- `tags`

## Public Coordinator

`InteractionCoordinator` is the public API:

- `registerInteraction(schema)`
- `recordIntent(intent)`
- `recordLock(interactionId, lockState)`
- `recordCooldown(interactionId, cooldown)`
- `inspect()`
- `getSnapshot()`
- `validate()`
- `runSelfChecks()`
- `shutdown()`

All public exports are isolated deep copies. No public method executes gameplay.

## Safety Boundary

Validation rejects missing ids, duplicate interaction ids, unsupported interaction types, missing `physicalObjectId`, unsafe eligibility, unsafe metadata/context, invalid cooldowns, invalid locks, client fields, remote fields, Workspace fields, Roblox Instances, functions, threads, userdata, cyclic tables, oversized strings, oversized payloads, deep payloads, animation fields, audio fields, UI fields, lighting fields, physics fields, movement fields, inventory execution fields, door execution fields, drawer execution fields, pickup execution fields, puzzle completion fields, Monster AI fields, Narrative ownership fields, Save ownership fields, Horror pacing fields, and Chapter/story/dialogue/cutscene fields.

## Future Use

Future door, drawer, item, puzzle, and inspection systems must consume these schemas through governed services. They must not bypass Physical Runtime, Gameplay Execution Bridge, Presentation Runtime, or Governance.
