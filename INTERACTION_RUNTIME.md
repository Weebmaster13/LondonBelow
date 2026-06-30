# Interaction Runtime

The Interaction Runtime is the reusable server-authoritative interaction layer for London Engine.

It is not a collection of one-off object scripts. It is the foundation future doors, keys, notes, levers, drawers, cabinets, hiding spots, puzzles, and chapter objects will use.

## Modules

`ServerScriptService/Gameplay/Interaction` contains:

- `InteractionService.lua`: authoritative request pipeline and orchestration.
- `InteractionTypes.lua`: server-facing interaction type bridge.
- `InteractionConfig.lua`: server interaction tuning.
- `InteractionRegistry.lua`: tagged interactable discovery and descriptors.
- `InteractionValidator.lua`: payload, range, line-of-sight, cooldown, and ownership validation.
- `InteractionState.lua`: counters, last results, cooldowns, cancellation state, and cleanup.
- `InteractionDiagnostics.lua`: read-only diagnostics and validation aggregation.
- `ObjectInteractionHandlers.lua`: generic reusable state transitions.
- `FeedbackService.lua`: server-approved presentation feedback dispatch.

## Server Request Flow

```text
Client raycast focus
-> RequestFocus remote
-> InteractionRegistry lookup
-> InteractionValidator range/line-of-sight checks
-> FocusUpdated remote
-> player input
-> RequestInteraction remote
-> InteractionValidator full validation
-> Interaction.Begin observation
-> ObjectInteractionHandlers execution
-> configured object observation
-> Interaction.Complete observation
-> Feedback remote
-> client presentation
```

The focus path is only a preview. The actual interaction request is always validated again.

## Supported Runtime Features

- Interaction IDs.
- Server-side registration from `LondonInteractable` tags.
- Priority metadata.
- Prompt text.
- Distance checks.
- Line-of-sight checks.
- Cooldowns.
- Enabled/disabled state.
- Locked/disabled failure behavior.
- Tap interactions now.
- Hold progress hooks for future UI and accessibility.
- Cooperative interaction metadata hooks.
- Multiplayer-safe request validation.

## Observations

The runtime emits:

- `Interaction.Begin`
- `Interaction.Complete`
- `Interaction.Cancel`
- `Interaction.Fail`
- `Interaction.OpenDoor`
- `Interaction.OpenDrawer`
- `Interaction.OpenCabinet`
- `Interaction.ToggleSwitch`
- `Interaction.PullLever`
- `Interaction.CollectibleFound`
- `Interaction.ReadNote`
- `Interaction.PickupKey`

Rejected requests emit `Interaction.Fail` with structured metadata. Rejected requests do not execute object state changes.

## Studio Setup

Tag an object with `LondonInteractable` and set attributes:

- `InteractionId`
- `InteractionKind`
- `Prompt`
- `Priority`
- `MaxDistance`
- `RequiresLineOfSight`
- `Cooperative`
- `Replayable`
- `InteractionEnabled`
- `ObservationId`
- `Meta_*` values for observation metadata

Production content should always use stable `InteractionId` values instead of generated full names.

## Future Integrations

- DoorService should own locks and special door rules.
- InventoryService should grant keys and collectibles.
- PuzzleService should consume switch/lever/cabinet results.
- Hiding systems should register hiding spots as interactables later.
- Lantern systems should use input and feedback hooks without owning interaction validation.
- Horror Director should react through Observation Engine, not direct interaction calls.

## Intentional Limits

- No final UI skin.
- No final audio assets.
- No puzzle answers.
- No inventory persistence.
- No chapter-specific object behavior.
- No Monster AI.
- No random horror events.

