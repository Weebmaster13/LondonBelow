# Lantern Production Review

The Lantern Runtime was reviewed as a long-term London Engine truth subsystem.

## What Was Reviewed

- `LanternService`
- `LanternState`
- `LanternValidator`
- `LanternConfig`
- `LanternDiagnostics`
- `LanternSignals`
- `LanternTypes`
- RemoteManager registration for the `Lantern` namespace
- Observation output for equipped, unequipped, on, off, low battery, and overuse
- DirectorCoordinator request behavior
- Governance and documentation boundaries

## Production Fixes

- Client attempts to set `equipped` are rejected as malformed toggle requests.
- Client-provided zone metadata is ignored on remote toggles.
- Toggle `requestId` values are remembered in bounded per-player replay caches.
- Replayed toggle requests are rejected and counted.
- Battery and overuse values are clamped.
- Low-battery and overuse observations use cooldowns to prevent spam.
- Director requests are throttled and suppressed while the player is in protected context.
- Unknown zone context is protected at equip and toggle time.
- Player removal and shutdown clear lantern state, recent changes, and replay caches.
- Diagnostics now expose state count, rejection count, replay count, Director request counts, suppression counts, cooldown counts, recent changes, and health.
- Self-checks verify malformed toggle rejection, not-equipped toggle rejection, replay rejection, server authority, and no Workspace mutation.

## Authority Boundary

The client can ask for a lantern toggle. It cannot claim that the lantern is equipped, choose the trusted zone, change battery, change overuse, force low-battery observations, or trigger final effects.

Future inventory systems should call `LanternService.equip` and `LanternService.unequip` from trusted server code. Future UI systems should consume `StateUpdated` and `RequestResult` as presentation-only data.

## Remaining Risks

- The final inventory/runtime integration does not exist yet.
- Battery depletion currently behaves as a hook, not a full resource economy.
- Presentation hooks exist, but there is no final UI, lighting execution, audio execution, or animation.
- Future save systems must decide whether lantern battery persists across checkpoints.

## Production-Ready Rationale

The runtime is production-ready as a Phase 12 foundation because it has one responsibility, protects server truth, rejects spoofed client state, bounds memory, exposes diagnostics, emits observations, requests Directors without executing effects, and cleans up player-owned state.

