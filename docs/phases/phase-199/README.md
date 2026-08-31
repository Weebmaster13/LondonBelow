# Phase 199 - Stealth, Hiding, Chase, Rescue, and Survival

## Baseline

Phase 199 creates the survival loop needed for Blackwater Descent before final monster rigging.

## Ownership

Owned by `BlackwaterStealthRuntime`, `BlackwaterPerceptionRuntime`, `BlackwaterChaseRuntime`, and `BlackwaterRunState`.

## Non-Ownership

This phase does not grant client movement authority, create networking, alter Roblox character controllers, persist progress, or claim measured chase feel without Studio evidence.

## Implementation

The server-side production layer calculates noise from interaction category and pressure, exposure from movement, hiding, and pressure, and stamina using deterministic difficulty profiles. Hiding types include wardrobe, under-table, shadow alcove, service cupboard, and emergency concealment. Each hiding type has capacity, search risk, and noise-on-entry data.

The chase runtime has explicit start, resolve, escape, death, and cancellation states. It prevents duplicate active chases, rejects missing targets, tracks target user ID, records chase counters, and exposes route decisions for foyer, service, gallery, and street loops. Deaths cancel cinematic state and resolve the active chase.

## Validation

`london:phase199:selfcheck` verifies noise/exposure functions, hiding capacity rejection, stamina drain/recovery, chase lifecycle, death integration, and server-owned outcome posture.

## Certification Boundary

Production Candidate only. Studio multiplayer chase routes, rescue timing, input feel, camera safety, and repeated death/recovery evidence are required.

## Known Limitations

The current survival model is deterministic and authoritative but still needs Studio playtesting for tuning and final physical hiding volumes.

## Next Handoff

Phase 200 uses the survival pressure model to make puzzle mistakes create recoverable danger.
