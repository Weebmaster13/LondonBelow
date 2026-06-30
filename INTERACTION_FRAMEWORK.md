# Interaction Framework

The Interaction Framework is the reusable server-authoritative object interaction layer for London Engine.

It supports exploration, environmental storytelling, cooperative play, and psychological tension without embedding Chapter 1 logic or Monster AI.

## Design Rules

- The client may detect focus and request interaction.
- The server validates every request.
- Every accepted interaction emits an Observation Engine fact when configured.
- Interactions are reusable and chapter-agnostic.
- Object state changes are server-owned.
- Feedback is presentation-only and sent after server acceptance.
- Puzzle, inventory, save, and horror systems must integrate through their own future modules instead of being hidden inside generic interaction code.

## Interactable Setup

A Studio object becomes interactable when it has the `LondonInteractable` CollectionService tag.

Supported attributes:

- `InteractionId`: stable unique ID. Required for production content.
- `InteractionKind`: `Door`, `Drawer`, `Cabinet`, `Switch`, `Lever`, `Collectible`, `Note`, `Key`, or `Generic`.
- `Prompt`: prompt text for temporary/debug UI.
- `Priority`: higher priority wins when multiple candidates compete.
- `MaxDistance`: server validation distance.
- `RequiresLineOfSight`: boolean.
- `Cooperative`: boolean hook for future multi-player interactions.
- `Replayable`: boolean.
- `InteractionEnabled`: false disables interaction.
- `ObservationId`: optional explicit ObservationRegistry ID.
- `Meta_*`: copied into observation metadata without the `Meta_` prefix.

Example attributes:

```text
Tag: LondonInteractable
InteractionId: foyer_front_door
InteractionKind: Door
Prompt: Open
Priority: 10
MaxDistance: 10
RequiresLineOfSight: true
InteractionEnabled: true
Meta_roomId: foyer
```

## Interaction Flow

```text
Client camera raycast
-> RequestFocus remote
-> server checks registered target, range, and line of sight
-> FocusUpdated remote
-> client shows prompt
-> player presses interact
-> RequestInteraction remote
-> server validates request again
-> reusable handler changes server state
-> ObservationService.observe()
-> Feedback remote
-> client renders presentation hook
```

Focus is convenience only. The server revalidates the actual interaction request.

## Object Kinds

`Door`

- Toggles `Open`.
- Emits `Interaction.OpenDoor` unless overridden.
- Sends door feedback hooks.

`Drawer`

- Toggles `Open`.
- Emits `Interaction.OpenDrawer`.

`Cabinet`

- Toggles `Open`.
- Emits `Interaction.OpenCabinet`.

`Switch`

- Toggles `On`.
- Emits `Interaction.ToggleSwitch`.

`Lever`

- Toggles `Pulled`.
- Emits `Interaction.PullLever`.

`Collectible`

- Marks `Consumed`.
- Disables future interaction.
- Emits `Interaction.CollectibleFound`.
- Does not grant inventory yet.

`Note`

- Sends a note presentation hook.
- Emits `Interaction.ReadNote`.
- Does not implement final note UI yet.

`Key`

- Marks `Consumed`.
- Emits `Interaction.PickupKey`.
- Does not implement final inventory truth yet.

## Multiplayer Rules

- All accepted state changes happen on the server.
- Late join behavior should be handled by future chapter/object state replication layers.
- Cooperative interactions should build on `Cooperative` descriptors but must add explicit shared-progress validation later.
- Clients cannot fake range, line of sight, readiness, ownership, or collected state.

## Failure Handling

Requests are rejected when:

- Payloads are malformed.
- The interaction is unknown.
- The target is disabled.
- The player is out of range.
- Line of sight is blocked.
- The target belongs to the player's character.
- The handler fails safely.

Rejected interactions return structured codes and do not emit observations.

## Future Integration

Future systems should extend this framework by adding adapters, not by bloating `InteractionService`:

- InventoryService grants items after accepted key/collectible interactions.
- PuzzleService listens for accepted switch/lever/cabinet state.
- DoorService owns lock state and special door logic.
- ObjectiveService consumes observations and interaction events.
- Horror Director reacts only through Observation Engine and Director approvals.
- Final UI replaces the temporary prompt presenter.

