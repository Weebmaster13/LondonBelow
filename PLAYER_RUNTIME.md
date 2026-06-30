# Player Runtime

The Player Runtime is the server-authoritative foundation for how a player exists inside London Engine.

It is not Chapter 1, Monster AI, final UI, final art, stamina gameplay, injury gameplay, or horror pacing. It owns durable player state contracts and hooks that future systems can safely build on.

## Modules

`ServerScriptService/Player` contains:

- `PlayerService.lua`: lifecycle owner, diagnostics, snapshots, player state API, and EventBus state-change signals.
- `PlayerTypes.lua`: lifecycle, movement, grounded, and runtime state types.
- `PlayerConfig.lua`: server defaults and future lock/restriction constants.
- `PlayerStateService.lua`: run-local authoritative player state store.
- `PlayerDiagnostics.lua`: read-only validation and diagnostic capture.

Movement profile application remains in `ServerScriptService/Gameplay/Player/PlayerControllerService.lua` because it is the gameplay bridge that receives input state from the Player Experience remotes.

## State Owned

The runtime tracks:

- Alive, dead, and spectating future lifecycle states.
- Grounded and airborne state.
- Walk, sprint, crouch, and stopped movement modes.
- Interaction lock state.
- Cinematic lock state.
- Current room, area, and chapter hooks.
- Movement restriction hooks.
- Future stamina, fear, and injury values.

These values are run-local engine state. Save data and checkpoint persistence belong to future Saving systems.

## Server Authority

Clients can request movement intent. The server decides what becomes accepted runtime state.

The Player Runtime does not trust clients with:

- Lifecycle truth.
- Grounded truth.
- Interaction lock truth.
- Cinematic lock truth.
- Room/area/chapter truth.
- Fear, injury, or stamina truth.

## Observation Flow

Accepted player movement can emit:

- `Movement.Walk`
- `Movement.StartSprint`
- `Movement.StopSprint`
- `Movement.Jump`
- `Movement.Land`
- `Movement.Crouch`

Future room volumes should emit `Exploration.EnterRoom` and `Exploration.ExitRoom` after server validation.
`Movement.Stop` is reserved until the runtime receives trusted locomotion-vector or humanoid movement stop data.

## Future Integration

Future systems should use Player Runtime hooks instead of inventing per-feature player state:

- Cutscenes set cinematic lock.
- Interactions set interaction lock.
- Chapter systems set current chapter, area, and room.
- Injury systems adjust movement restrictions.
- Fear systems may read presentation hooks but must not store trusted fear on the client.
- Save systems decide what, if anything, persists.

## Failure Handling

- Missing state creates a safe default state.
- Players leaving clear run-local state.
- Invalid movement profile config fails validation.
- Client presentation failure does not corrupt server state.
