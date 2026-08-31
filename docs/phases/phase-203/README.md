# Phase 203 - Replayability, Difficulty, Secrets, Mastery, and Ethical Retention

## Baseline

Phase 203 adds deterministic replay structure without manipulative retention mechanics.

## Ownership

Owned by `BlackwaterReplayRuntime`, `BlackwaterRunState`, and difficulty/ending/evidence config.

## Non-Ownership

This phase does not add monetization, gambling, artificial scarcity, daily streaks, pay-to-win progression, DataStore writes, or unstable active-run persistence.

## Implementation

The run seed controls approved clue, evidence, and ward variation while preserving solvability. Difficulty presets are Story, Standard, Investigator, and Nightmare. Difficulty affects chase intensity, stamina forgiveness, and hint strength without disabling accessibility.

The replay runtime creates an end-of-run summary containing ending, deaths, rescues, hunts survived, evidence count, relic count, difficulty, and run seed. Multiple endings and optional evidence create reasons to replay based on discovery and mastery.

## Validation

`london:phase203:selfcheck` verifies difficulty presets, replay summary fields, run seed stability, ending count, discovery tracking, no persistence writes, and ethical retention boundaries.

## Certification Boundary

Production Candidate only. Studio replay reset, all-ending playthroughs, and human replay-interest evidence are required.

## Known Limitations

Persistence remains intentionally absent until an approved persistence authority is connected to stable, appropriate progression data.

## Next Handoff

Phase 204 integrates and hardens the full Phase 184–203 chain.
