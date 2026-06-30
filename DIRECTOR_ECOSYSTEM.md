# Director Ecosystem

Phase 7 creates the London Engine Director Ecosystem.

This is architecture only. It does not add Chapter 1, Monster AI, final UI, final art, actual scares, real lighting behavior, real audio behavior, real music behavior, or gameplay logic.

## Golden Flow

```text
Observation Engine
-> DirectorCoordinator
-> relevant Directors
-> approval response
-> future execution systems
-> client presentation
```

The Observation Engine understands reality. Directors interpret reality. Execution systems perform approved actions. Presentation systems show results.

## Director Tree

```text
London Engine
-> DirectorCoordinator
   -> Psychological Horror Director
   -> Narrative Director
   -> Story Director
   -> Environment Director
   -> Lighting Director
   -> Audio Director
   -> Music Director
   -> Monster Director
   -> Puzzle Director
   -> Save Director
   -> Difficulty Director
   -> Performance Director
```

## Example

```text
Observation: Player has been alone for 6 minutes.
-> Horror Director: tension is high.
-> Monster Director: reveal requested.
-> Lighting Director: darken corridor requested.
-> Coordinator: approved Lighting, deferred Monster Reveal.
-> Reason: player has not yet reached intended narrative beat.
```

The Coordinator may approve local atmosphere pressure while deferring major monster pressure until Narrative allows the beat.

## Current Implementation

`ServerScriptService/Horror/DirectorEcosystem` contains:

- `DirectorCoordinator.lua`
- `DirectorTypes.lua`
- `DirectorSignals.lua`
- `DirectorContract.lua`
- `DirectorRegistry.lua`
- `FoundationDirector.lua`

The foundation Directors expose the standard contract and capabilities but do not execute real behavior.

