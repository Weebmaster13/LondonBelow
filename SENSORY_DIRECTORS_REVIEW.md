# Sensory Directors Review

Phase 11 was audited as the approval-only sensory layer for London Engine. The review covered Lighting Director, Audio Director, DirectorCoordinator integration, Governance contracts, World Intelligence policy use, diagnostics, lifecycle cleanup, and documentation.

## Issues Found

- Explicit invalid `lightingKind` or `audioKind` values could fall back to broad request defaults instead of rejecting.
- Cooldown seconds could be influenced by request metadata, which could weaken spam protection.
- Diagnostics exposed cooldown tables but not cooldown counts or cooldown creation counters.
- Self-checks did not prove unknown-zone conservatism strongly enough.
- Audio monster-support pressure could be allowed in known zones if fake-sound policy allowed it but monster presence was denied.

## Fixes Made

- Explicit invalid sensory request kinds now reject with clear reasons.
- Cooldowns are definition-owned and clamped to configured min/max bounds.
- Deferred and rejected requests do not create cooldowns.
- Unknown-zone self-checks now prove major lighting and silence-drop pressure defer.
- Self-checks prove malformed requests reject and approval-only benign requests can approve.
- Diagnostics now include cooldown counts and cooldown creation counts.
- Audio fake footsteps and whispers are denied when World Intelligence denies monster presence.
- Pressure deltas from observations are clamped to prevent sudden pressure jumps.

## Authority Rules

- Lighting and Audio Directors approve future actions only.
- No Director mutates Workspace, Roblox Lighting, Sound instances, UI, final assets, or client state.
- Future execution systems must consume approved Director decisions and must not invent pacing.
- World Intelligence policy is mandatory for every approval path.

## Remaining Risks

- There are no physical execution systems yet, by design.
- No Chapter 1 world profiles exist yet, so most non-protective pressure in unknown zones remains deferred.
- Director self-checks are module-level checks; future integration tests should exercise the full DirectorCoordinator path in Studio.

## Testing Notes

Validation confirmed:

- malformed requests reject
- invalid explicit request kinds reject
- unknown zones deny major sensory pressure
- safe-room/puzzle protections are enforced through World Intelligence policy
- cooldown memory is bounded
- generated Rojo artifacts are not committed

