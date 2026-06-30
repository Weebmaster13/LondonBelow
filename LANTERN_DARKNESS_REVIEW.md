# Lantern Darkness Review

Phase 12 creates the reusable truth layer for lantern usage and darkness exposure.

## What Was Built

- `LanternService`
- `LanternState`
- `LanternValidator`
- `LanternDiagnostics`
- `DarknessService`
- `DarknessExposureTracker`
- `DarknessDiagnostics`
- Observation definitions for required lantern and darkness events.
- Governance contracts for Lantern Runtime and Darkness Runtime.
- Rojo mappings for `ServerScriptService/Gameplay/Lantern` and `ServerScriptService/Gameplay/Darkness`.

## Authority Rules

- Server owns lantern equipped truth.
- Server owns lantern on/off truth.
- Server owns battery/fuel hooks.
- Server owns overuse truth.
- Server owns darkness exposure truth.
- Client can request lantern toggle only.
- Client cannot create darkness truth.
- Future clients may present server-approved hooks only.

## Director Rules

Lantern and Darkness may request Lighting, Audio, and Environment Director approvals. These requests are not effects. Future execution systems must consume approved decisions and remain separate.

## Protection Rules

Unknown zones remain conservative.

Safe rooms suppress hostile pressure.

Puzzle rooms protect readability, comprehension, and cooperation.

## Remaining Risks

- No physical darkness zones exist yet.
- No inventory system exists yet to equip/unequip lanterns through gameplay.
- No final client presentation exists yet.
- No final lighting or audio execution exists yet.

These are intentional Phase 12 boundaries.

