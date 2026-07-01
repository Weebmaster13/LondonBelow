# Darkness Production Review

The Darkness Runtime was reviewed as a reusable server-owned exposure subsystem.

## What Was Reviewed

- `DarknessService`
- `DarknessExposureTracker`
- `DarknessConfig`
- `DarknessDiagnostics`
- `DarknessSignals`
- `DarknessTypes`
- Observation output for entry, exit, exposure increase, and protected zones
- DirectorCoordinator request behavior
- Scheduler update lifecycle
- Governance and documentation boundaries

## Production Fixes

- Unknown world context is protected by default.
- Safe rooms and puzzle-protected rooms suppress hostile darkness pressure.
- Exposure intensity and exposure totals are clamped.
- Exposure observations are throttled to prevent update spam.
- Director requests are throttled after exposure crosses the configured threshold.
- Protected states suppress Director pressure.
- Unknown, safe-room, and puzzle protection are counted separately.
- Player removal and shutdown clear darkness state and recent event memory.
- Diagnostics now expose tracked state count, protected counts, Director request counts, suppression counts, cooldown counts, recent events, and health.
- Self-checks verify unknown-zone protection, conservative world policy, server authority, and no Workspace mutation.

## Authority Boundary

The client does not own darkness truth. Future server-owned zone systems may call `enterDarkness`, `exitDarkness`, and `updateExposure`. Client presentation may react later to server-approved state, but it may not create fear, exposure, zone, or Director truth.

## Director Boundary

Darkness requests are approval-only requests to Lighting, Audio, and Environment Directors. They do not mutate Workspace, Roblox Lighting, sound, UI, camera, monster state, or Chapter 1 content.

Failed, deferred, rejected, or suppressed Director requests do not change exposure truth.

## Remaining Risks

- No physical zone binder exists for darkness volumes yet.
- No final lighting or audio execution exists yet.
- Future chapter systems must provide trusted world context from server-owned zones.
- Future accessibility settings may need to adjust presentation intensity without changing server exposure truth.

## Production-Ready Rationale

The runtime is production-ready as a Phase 12 foundation because it is server-authoritative, conservative in unknown spaces, protected in safe and puzzle spaces, bounded in memory, throttled against spam, observable through diagnostics and snapshots, and free of final content or physical mutation.

