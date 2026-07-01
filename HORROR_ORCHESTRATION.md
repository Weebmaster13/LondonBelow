# Horror Orchestration Framework

Phase 15.5 adds the server-only coordination layer that decides how horror systems should work together.

It does not execute horror. It does not move monsters, spawn NPCs, play sounds, flicker lights, mutate Workspace, create remotes, add final scares, or build Chapter content.

## Purpose

Monster Intelligence may say a monster is interested, curious, waiting, investigating, searching, pressuring, or leaving. Horror Orchestration decides whether that intent should become silence, delay, fake presence, environmental support, audio support, lighting support, monster pressure request, chase preparation request, release, or no action.

Sometimes the best horror action is no action.

## Owns

- Cross-system horror coordination.
- Bounded pressure budget.
- Silence and release decisions.
- Escalation approval recommendations.
- Chase preparation recommendations.
- Scare eligibility checks.
- Emotional beat protection.
- Multi-system approval-only bundles.
- Diagnostics, snapshots, and self-checks.

## Does Not Own

Gameplay truth, Monster AI, movement, pathfinding, damage, animations, Lighting mutation, audio playback, Workspace mutation, final UI, final scares, chapter content, or client authority.

## London Bible Integration

The framework preserves "nothing is random" by requiring decision reasons. It protects rare, earned, meaningful scares by rejecting scares without meaning, suppressing safe-room scares, protecting puzzle readability, and treating silence as a valid horror decision.

## Deferred Work

Future phases may connect these bundles to Monster Director, Narrative Runtime, Journal/Identity Runtime, and presentation systems. This phase stops at approval-only recommendations.

## Production Hardening Notes

- Pressure decays during scheduled cleanup.
- Pressure deltas are clamped so repeated requests cannot spike infinitely.
- Request IDs are bounded and duplicate IDs reject.
- Safe-room and puzzle-room scare suppression takes priority before release or escalation.
- Coordination bundles are recommendations only and explicitly set `executionAllowed = false`.
