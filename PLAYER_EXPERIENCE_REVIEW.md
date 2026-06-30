# Player Experience Framework Review

This document records the Phase 6 audit of the London Engine Player Experience Framework.

This review did not add Chapter 1, Monster AI, final UI, final art, copied mechanics, or one-off gameplay scripts.

## Reviewed

- `ServerScriptService/Player/PlayerService.lua`
- `ServerScriptService/Player/PlayerStateService.lua`
- `ServerScriptService/Gameplay/Player/PlayerControllerService.lua`
- `ServerScriptService/Gameplay/Interaction/InteractionService.lua`
- `ServerScriptService/Gameplay/Interaction/InteractionValidator.lua`
- `ServerScriptService/Gameplay/Interaction/InteractionState.lua`
- `ServerScriptService/Gameplay/Interaction/InteractionRegistry.lua`
- `ServerScriptService/Gameplay/Interaction/ObjectInteractionHandlers.lua`
- `ServerScriptService/Gameplay/Interaction/FeedbackService.lua`
- Client player, input, camera, interaction, prompt, feedback, and accessibility controllers
- ObservationRegistry additions
- Governance contracts
- Rojo mapping
- `PLAYER_RUNTIME.md`
- `INTERACTION_RUNTIME.md`
- `PLAYER_EXPERIENCE.md`

## Issues Found

- `ServerScriptService/Player` was not mapped in `default.project.json`, so Rojo would not sync the Player Runtime into Studio.
- Interaction cooldowns were consumed during validation, which meant failed range or line-of-sight checks could put an interaction on cooldown.
- Sprint, crouch, and jump observations could repeat under repeated movement-state remotes instead of only firing on state transitions.
- Camera smoothing used `1 - smoothing`, making reduced-motion mode snappier instead of calmer.
- CharacterAdded connections were stored in the general lifecycle list and not cleaned per player on disconnect.
- Client focus refresh was close to the previous remote rate limit, which could create avoidable focus rejections.
- Interaction registry did not fail closed on duplicate interaction IDs.
- Player location hooks published internal events but did not emit `Exploration.EnterRoom` or `Exploration.ExitRoom`.
- Interaction diagnostics did not expose cooldown pressure.

## Fixes Made

- Added explicit Rojo mapping for `ServerScriptService/Player`.
- Split cooldown checking and cooldown marking so cooldown is consumed only after validation succeeds.
- Limited sprint, crouch, and jump observations to state transitions.
- Removed misleading `Movement.Stop` emission until trusted movement-vector stop data exists.
- Corrected camera smoothing so reduced motion uses gentler interpolation.
- Added per-player CharacterAdded cleanup in `PlayerExperienceService`.
- Increased Player Experience remote rate limit to allow normal focus polling without riding the limit.
- Added duplicate interaction ID tracking and validation failure.
- Added PlayerService observations for server-owned room enter and exit hooks.
- Added cooldown count to interaction diagnostics.

## Server Authority Rules Confirmed

- The client requests movement and interaction intent only.
- The server owns player runtime state, interaction acceptance, object state attributes, observations, and feedback permission.
- Focus validation is convenience; interaction requests are validated again.
- Rejected interactions do not execute object handlers.
- Feedback is sent only after server acceptance.

## Remaining Risks

- `Movement.Stop` needs future trusted locomotion-vector or humanoid state integration before it can be emitted honestly.
- Mobile controls currently use Roblox ContextActionService touch buttons as hooks, not final mobile UX.
- Prompt UI is a debug/testing surface and must be replaced by final UI later.
- Object handlers intentionally change generic attributes only; future DoorService, InventoryService, PuzzleService, and Hiding systems must own specialized truth.
- Camera controller is a foundation and does not yet handle cutscene takeover, FOV effects, or character yaw synchronization.
- Duplicate ID validation can only catch registered/tagged interactables present in the server runtime.

## Testing Checklist

- Join Studio with one player and verify Player Runtime appears in diagnostics/snapshots.
- Confirm movement remotes do not spam repeated sprint/crouch/jump observations.
- Tag a part with `LondonInteractable`, set `InteractionId`, `InteractionKind`, and `Prompt`, then verify focus and interaction result.
- Test out-of-range interaction rejection.
- Test line-of-sight blocked interaction rejection.
- Test duplicate `InteractionId` content fails validation.
- Test collectible/key interaction disables future interaction through `InteractionEnabled = false`.
- Test player leaving clears player state, interaction state, and character connections.
- Test controller and mobile action hooks produce requests without owning truth.
- Test reduced motion camera mode before adding future camera effects.

## Future Work

- Add trusted movement-vector sampling for `Movement.Stop`.
- Add final mobile input surfaces.
- Add polished prompt UI and accessibility settings persistence.
- Add DoorService, InventoryService, PuzzleService, HidingService, and LanternService integrations.
- Add cutscene camera takeover through server-approved presentation bridges.
- Add automated multiplayer interaction tests once the test harness exists.

