# Horror Pressure Model Review

This review covers the Phase 15.5 pressure model after production hardening.

## Reviewed Modules

- `PressureBudgetModel`
- `SilenceDecisionModel`
- `ReleaseDecisionModel`
- `EscalationModel`
- `ScareEligibilityModel`
- `ChasePreparationModel`
- `EmotionalBeatModel`
- `HorrorOrchestrationState`
- `HorrorOrchestrator`
- `HorrorOrchestrationSelfChecks`

## Pressure Bounds

Pressure is clamped from 0 to 100. Per-request pressure deltas are capped by `MaxPressureDeltaPerRequest`, and scheduled cleanup decays pressure over time. Sensory, emotional, and multiplayer loads are also clamped from 0 to 100 before entering diagnostics or decision logic.

## Decision Proofs

The self-check suite now proves:

- Pressure stays bounded.
- Silence can be selected.
- Release triggers after high pressure.
- Scares reject without narrative or emotional meaning.
- Safe rooms suppress scare candidates.
- Puzzle rooms protect readability.
- Overloaded players suppress escalation.
- Duplicate requests reject.
- Expired requests reject.
- Coordination bundles remain approval-only.
- Shutdown clears queue and state.
- No Workspace mutation, Monster AI execution, or client authority is introduced.

## Suppression Priority

Scare suppression for safe rooms, puzzle rooms, overload, recent use, and missing meaning happens before escalation and release behavior can turn a scare candidate into pressure. This prevents a protected space from accidentally becoming hostile because global pressure is high.

## Remaining Risks

Future systems that consume orchestration bundles must continue treating them as recommendations. A later Presentation Runtime or Monster AI phase must not reinterpret pressure budget values as permission to execute.
