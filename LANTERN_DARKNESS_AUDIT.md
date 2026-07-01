# Lantern Darkness Audit

Phase 12 was audited as a reusable gameplay truth layer, not as Chapter 1 content.

This audit covered `LanternService`, `LanternState`, `LanternValidator`, `LanternConfig`, `LanternDiagnostics`, `LanternSignals`, `LanternTypes`, `DarknessService`, `DarknessExposureTracker`, `DarknessConfig`, `DarknessDiagnostics`, `DarknessSignals`, `DarknessTypes`, observation registration, Bootstrap and Framework integration, RemoteManager usage, Governance contracts, and the Lantern/Darkness documentation.

## Audit Summary

The systems remain within Phase 12 boundaries:

- No Chapter 1 logic was added.
- No Monster AI was added.
- No final UI, art, scares, audio playback, or lighting effects were added.
- No Workspace or Roblox Lighting mutation was added.
- No client-owned lantern or darkness truth was introduced.

The production hardening focused on preventing spoofed client truth, replayed toggle requests, observation spam, Director request spam, unsafe unknown-zone pressure, and unbounded diagnostic memory.

## Issues Found

- Lantern toggle payloads previously accepted zone-shaped metadata into the request contract. Even though the server owned most truth, this made future callers more likely to treat client zone context as trusted.
- Lantern toggle requests had no request-id replay memory.
- Lantern low-battery and overuse observations could repeat too quickly during repeated toggles.
- Lantern Director requests could be submitted repeatedly during rapid state changes.
- Lantern unknown-zone protection needed to be enforced again at toggle time, not only at equip time.
- Darkness exposure observations could fire every exposure update.
- Darkness Director requests could fire too often once exposure crossed the configured threshold.
- Darkness protection counters did not distinguish unknown, safe-room, and puzzle protections.
- Diagnostics did not expose enough hardening evidence for rejections, replays, protected states, throttles, or Director request suppression.
- Self-checks did not directly prove malformed toggles, not-equipped toggles, replayed toggles, unknown-zone protection, and no Workspace mutation.

## Fixes Made

- `LanternValidator.sanitizeToggle` now treats client zone metadata as untrusted context and never returns it as authoritative zone truth.
- `LanternService.requestToggle` rejects client attempts to set `equipped`.
- `LanternState` now tracks bounded recent request IDs per player and rejects replayed toggle request IDs.
- `LanternState` bounds recent state changes and clears replay memory on player removal and shutdown.
- Lantern battery, overuse, and toggle-derived values are clamped.
- Low-battery and overuse observations now use cooldowns.
- Lantern Director request submission now uses a cooldown and is suppressed in protected zones.
- Lantern unknown-zone toggles now stay protected at the final request path.
- `DarknessExposureTracker` clamps exposure and intensity-derived growth.
- Darkness exposure observations are throttled.
- Darkness Director requests are throttled and suppressed for protected states.
- Unknown zones, safe rooms, and puzzle-protected rooms increment distinct protection counters.
- Diagnostics now expose rejection counts, replay counts, protected counts, Director request counts, suppression counts, cooldown counts, tracked state counts, and health state.
- Self-checks now cover malformed toggles, not-equipped toggles, replayed toggles, unknown-zone darkness protection, and no Workspace mutation.

## Server Authority Rules

- Clients may request lantern on/off only.
- Clients may not equip or unequip lanterns.
- Clients may not set battery, overuse, cooldown, protection, or zone truth.
- Clients may not create darkness entry, exit, exposure, or protection truth.
- Client zone metadata is untrusted and ignored by the lantern remote path.
- Trusted server systems may pass world context when equipping lanterns or entering darkness.
- Director requests are approval requests only; they do not mutate gameplay truth.

## Protected-Zone Rules

Unknown zones fail protected. They may preserve basic truth, but they suppress hostile Director pressure.

Safe rooms suppress hostile lantern and darkness pressure.

Puzzle rooms protect visibility, comprehension, and cooperation. Lantern and darkness may still track truth, but they do not escalate unfair sensory pressure.

## Director Request Rules

Lantern and Darkness may request Lighting, Audio, and Environment approvals only after their local truth changes justify it.

Failed, deferred, rejected, or suppressed Director requests do not change lantern state, darkness state, battery, exposure, overuse, or protection truth.

Cooldowns are local anti-spam controls. They are not gameplay effects and are cleared with runtime state on shutdown.

## Remaining Risks

- No physical darkness zones exist yet.
- No inventory system exists yet to call trusted lantern equip and unequip paths.
- No execution systems exist yet for final lighting, audio, or environment presentation.
- Future zone binders must stay server-owned and avoid client truth.
- Future battery/fuel progression will need additional save and inventory integration.

These risks are intentional Phase 12 boundaries.

