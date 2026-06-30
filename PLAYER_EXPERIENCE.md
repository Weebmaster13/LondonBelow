# Player Experience Foundation

Phase 6 builds the reusable first-person player experience layer for London Engine.

This is not Chapter 1, Monster AI, copied level design, final UI, or final art. It is the chapter-agnostic foundation that future London Below chapters will use for movement, camera, interaction, prompts, feedback, and multiplayer-safe player state.

## Goals

- Smooth first-person exploration.
- Responsive walking, sprinting, crouching, and jumping.
- Server-authoritative interaction outcomes.
- Reusable object interactions for doors, drawers, cabinets, switches, levers, collectibles, notes, and keys.
- Observation Engine integration for trusted gameplay facts.
- Multiplayer-safe validation and synchronization.
- Accessibility hooks for reduced motion, camera tuning, haptics, and future presentation preferences.
- Diagnostics and snapshots for production debugging.

## Runtime Modules

Server modules:

- `ServerScriptService/Gameplay/PlayerExperienceService.lua`: Framework lifecycle owner, remotes, diagnostics, snapshots, player lifecycle, and subsystem orchestration.
- `ServerScriptService/Gameplay/Player/PlayerControllerService.lua`: movement profiles, server movement state, speed application, and movement observations.
- `ServerScriptService/Gameplay/Interaction/InteractionService.lua`: authoritative interaction request validation, range checks, line-of-sight checks, observation emission, and result generation.
- `ServerScriptService/Gameplay/Interaction/InteractionRegistry.lua`: tagged interactable registration, descriptor construction, lookup, priority, and inspection.
- `ServerScriptService/Gameplay/Interaction/ObjectInteractionHandlers.lua`: reusable object state transitions and feedback hooks.
- `ServerScriptService/Gameplay/Interaction/FeedbackService.lua`: server-approved presentation instruction dispatch.

Client modules:

- `StarterPlayerScripts/ClientCore/PlayerExperienceClient.client.lua`: client composition runner.
- `StarterPlayerScripts/ClientCore/Networking/PlayerExperienceNetwork.lua`: waits for RemoteManager-created remotes and sends requests.
- `StarterPlayerScripts/ClientCore/Input/PlayerInputController.lua`: keyboard/controller movement and interaction input.
- `StarterPlayerScripts/ClientCore/Camera/FirstPersonCameraController.lua`: smooth first-person camera foundation and reduced-motion support.
- `StarterPlayerScripts/ClientCore/Effects/FeedbackController.lua`: presentation-only feedback hook receiver.
- `StarterPlayerScripts/ClientUI/HUD/InteractionPromptController.lua`: minimal testing prompt, not final UI.

Shared modules:

- `ReplicatedStorage/Config/PlayerExperienceConfig.lua`: movement, camera, accessibility, remote, and interaction tuning.
- `ReplicatedStorage/Shared/PlayerExperienceTypes.lua`: shared Luau contracts.
- `ReplicatedStorage/Shared/PlayerExperienceRemoteNames.lua`: remote names and namespace.

## Server Authority

The client may:

- Capture input.
- Raycast for focus candidates.
- Request focus validation.
- Request an interaction.
- Render prompts, camera, audio, visual, haptic, and screen-effect hooks.

The server owns:

- Movement profile truth.
- Accepted movement state.
- Interaction range validation.
- Line-of-sight validation.
- Object state attributes such as `Open`, `On`, `Pulled`, and `Consumed`.
- Observation emission.
- Feedback permission.

Clients never complete an interaction by themselves. A prompt means "you may ask"; it does not mean "the action happened."

## Movement Foundation

The default profile supports:

- Walk.
- Sprint.
- Crouch.
- Jump.
- Optional future stamina.
- Camera height and crouch camera height.

The server applies speed and jump settings through `PlayerControllerService`. Future stamina should plug into the profile and validation path without moving authority to the client.

## Camera Foundation

The first-person camera is local presentation. It supports:

- Mouse look.
- Pitch limits.
- Smooth interpolation.
- Reduced-motion smoothing.
- Future fear-effect hooks.

Horror systems must not directly own the camera. They should request approved presentation through future execution/presentation bridges.

## Feedback Foundation

Feedback instructions are structured:

- `Audio`
- `Visual`
- `Prompt`
- `Haptics`
- `ScreenEffect`

The current client prints debug feedback and supports basic haptic hooks. Future UI/audio/art systems should replace the presentation implementation without changing server authority.

## Observations

Phase 6 emits or prepares these reusable observations:

- `Movement.StartSprint`
- `Movement.Crouch`
- `Movement.Jump`
- `Movement.Walk`
- `Interaction.OpenDoor`
- `Interaction.OpenDrawer`
- `Interaction.OpenCabinet`
- `Interaction.ToggleSwitch`
- `Interaction.PullLever`
- `Interaction.CollectibleFound`
- `Interaction.ReadNote`
- `Interaction.PickupKey`

Future chapter gameplay must add new observations to `ObservationRegistry` before relying on them.

## Governance

`Player Experience Foundation` is registered as a Governance contract. It declares:

- Gameplay ownership.
- Observation output.
- Server-authoritative validation.
- RemoteManager usage.
- Diagnostics and snapshots.
- Cleanup behavior.
- Multiplayer guarantees.
- Failure modes.

Future changes must keep that contract honest. If player experience begins owning inventory persistence, puzzle solving, horror pacing, or final art, the system has drifted and should be split.

## Future Work

- Add real stamina with server validation.
- Add mobile-specific interaction affordances.
- Add accessibility settings persistence.
- Add polished prompt UI and localization.
- Add chapter-specific interaction adapters.
- Add shared cooperative interaction counters.
- Add inventory/key integration after the inventory phase exists.
- Add richer camera effect execution bridges after Director approvals exist.

