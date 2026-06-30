# Environment Director

The Environment Director is London Engine's building and world intelligence layer. It approves subtle environmental reactions so London Below can feel watched, breathing, and intentional without becoming random noise.

It owns environmental reaction approvals, room and zone pressure state, building attention state, environment memory, reaction cooldowns, diagnostics, snapshots, and future execution contracts.

It does not own Monster AI, final audio playback, final lighting playback, puzzle truth, story canon, final art, client-owned weather truth, Chapter 1 content, or physical object movement without the execution bridge.

## Flow

```text
Observation Engine
-> DirectorCoordinator
-> Environment Director
-> reaction selection
-> approval or deferral
-> EnvironmentExecutionBridge
-> future execution systems
```

The Director is patient by design. Silence and stillness are valid decisions. Early reactions should be small: fog thickens, rain softens, wind changes, a distant door settles, or a room feels colder.

## Integration

`EnvironmentDirector` implements the lower-case Director contract and registers itself as the `Environment` domain with `DirectorCoordinator`. It also runs as a Framework module so diagnostics, snapshots, cooldown cleanup, and EventBus subscriptions follow the engine lifecycle.

## Fairness

The selector suppresses reactions that would damage puzzle fairness, safe-room protection, chase readability, group play, or cooldown discipline. Major building attention is documented as requiring future Narrative approval before real execution systems use it.

## Not Implemented Yet

No maps, art, lighting, audio, object motion, weather mutation, monster behavior, Chapter 1 scripting, or final UI are implemented in this phase.
