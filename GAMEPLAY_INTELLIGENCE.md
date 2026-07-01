# Gameplay Intelligence Framework

Phase 13 creates the reusable gameplay truth layer for London Engine.

This is not Chapter 1 content. It is not a doors-and-keys one-off. It is the foundation future chapters use for objects, doors, locks, keys, inventory, objectives, puzzle graphs, hints, gameplay memory, observations, diagnostics, snapshots, and Director approval hooks.

## Core Rules

- Server owns gameplay truth.
- Clients never own inventory, key, door, objective, object, or puzzle truth.
- No Chapter 1 puzzle, map, monster, scare, final UI, final art, or Workspace mutation belongs here.
- Every gameplay fact should become an Observation Engine fact before Directors interpret it.
- Director requests are approval-only and cannot execute final scares, lighting, audio, or environment changes.
- Unknown world context stays conservative. Puzzle rooms protect comprehension. Safe rooms suppress hostile pressure.

## Runtime Modules

- `GameplayCoordinator`: lifecycle, diagnostics, snapshots, and self-check facade.
- `GameplayRegistry`: generic reusable gameplay definition registry.
- `GameplayState`: bounded recent gameplay event and counter state.
- `GameplayMemory`: bounded behavioral memory for repeated interactions, locked attempts, puzzle errors, and progress.
- `ObjectRuntime`: stable object definitions and object state truth.
- `DoorService`: server-owned door state machine.
- `InventoryService`: server-owned item containers.
- `KeyService`: key data and unlock validation.
- `ObjectiveService`: reusable objective start/progress/complete/fail truth.
- `PuzzleService`: graph-based puzzle progress and hint hooks.

## Golden Flow

```text
Trusted server gameplay change
-> Observation Engine fact
-> Director Ecosystem approval
-> Future execution system
-> Client presentation
```

Phase 13 builds the first two steps and approval hooks. It does not build physical execution.

## Self-Checks

`GameplayCoordinator.runSelfChecks()` validates duplicate ID rejection, invalid door transition rejection, key unlock data flow, objective progression, puzzle graph validation, impossible graph rejection, missing dependency rejection, bounded memory, and shutdown cleanup.
