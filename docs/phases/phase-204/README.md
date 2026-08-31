# Phase 204 - Grand Production Integration, Optimization, QA, Playtesting, and Certification Gate

## Baseline

Phase 204 integrates Phases 184–203 into one production candidate chapter chain while keeping certification evidence honest.

## Ownership

Owned by `BlackwaterProductionCoordinator`, which binds environment, monster, perception, stealth, chase, puzzle, investigation, narrative, cinematic, audio, replay, and run-state modules into the existing Chapter 196 vertical-slice coordinator.

## Non-Ownership

This phase does not certify Studio runtime execution, fabricate performance numbers, fabricate human playtest feedback, create final art/audio, add networking, add persistence, start Chapter 1, or replace the Phase 184–195 presentation stack.

## Lifecycle

Initialization order is configuration and run seed, world construction, environment runtime, puzzle/evidence runtime, narrative runtime, monster runtime, stealth/perception runtime, chase runtime, cinematic runtime, audio runtime, replay runtime, player admission, objective reconciliation, death/recovery, replay summary, and shutdown cleanup. Shutdown reverses owned runtime state and preserves the existing world-builder cleanup path.

## Integration

The Chapter 196 coordinator registers `blackwaterProductionProgram` diagnostics and snapshot providers. It invokes production validation after ordinary server interaction validation and before visual/world mutation. Objective success updates narrative, discovery, relic, environment, Bailiff, chase, cinematic, audio, ending, and replay state through one coordinator.

## Validation

`london:phase204:selfcheck` verifies module presence, lifecycle ordering, provider integration, root attributes, forbidden surfaces, docs, and Phase 197–204 source consistency. Phase 184–196 regression scripts remain available through existing package commands.

## Certification Boundary

Production Candidate only. Phase 108 remains the latest Production Certified milestone. Studio playthrough, performance profiling, human testing, final art review, and final audio review remain blocked until authoritative evidence is imported.

## Quality Scorecard

Static-estimated only: world/art 6, atmosphere 7, exploration 7, monster intelligence 6, stealth 6, chase 6, puzzles 6, narrative 7, cinematics 5, audio 5, replayability 6, multiplayer 6, accessibility 7, performance 6, stability 7, originality 8, cohesion 7.

## Known Limitations

No category receives a Studio-verified score. Final certification requires real Roblox Studio evidence.

## Next Handoff

Phase 205 should focus on importing authoritative Studio playthrough evidence and prioritizing P0/P1 defects found during actual testing.
