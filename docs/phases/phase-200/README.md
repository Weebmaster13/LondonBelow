# Phase 200 - Investigation, Deduction, Wards, Puzzles, and House Reconfiguration

## Baseline

Phase 200 replaces shallow prompt following with deterministic clue and ward logic.

## Ownership

Owned by `BlackwaterPuzzleRuntime`, `BlackwaterInvestigationRuntime`, `BlackwaterRunState`, and `BlackwaterProductionConfig`.

## Non-Ownership

This phase does not persist evidence, auto-solve puzzles on the client, create remotes, or allow clients to declare correctness.

## Implementation

The production config defines deterministic run seeds, ward orders, symbols, and clue-room routes. The puzzle runtime validates ward order before the main interaction mutates objective state. Wrong ward attempts are rejected and recorded without making the run unrecoverable. The investigation runtime picks optional evidence deterministically from objective identity and run seed, then records discoveries into the run state and replicated case-file attributes.

The house reconfiguration path is connected through `BlackwaterEnvironmentProductionRuntime.applyObjective`, which changes environment stage, reactive materials, and route metadata as puzzle and archive milestones advance.

## Validation

`london:phase200:selfcheck` verifies seed definitions, ward validation, incorrect-order rejection, hint levels, optional evidence, deterministic clue selection, and validation-before-mutation ordering.

## Certification Boundary

Production Candidate only. Studio playthrough evidence is required to prove clue sufficiency, route readability, brute-force resistance, and multiplayer puzzle concurrency.

## Known Limitations

The puzzle has deterministic clue logic and server validation, but the final clue props and puzzle affordance art remain outstanding.

## Next Handoff

Phase 201 uses investigation results to drive character revelation, cinematics, and endings.
