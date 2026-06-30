# World Intelligence Review

Phase 10 was audited as a passive production contract layer. The review focused on preventing future systems from treating world metadata as direct gameplay commands.

## Files Reviewed

- `src/ServerScriptService/World/WorldTypes.lua`
- `src/ServerScriptService/World/WorldConfig.lua`
- `src/ServerScriptService/World/WorldProfileRegistry.lua`
- `src/ServerScriptService/World/WorldZoneContext.lua`
- `src/ServerScriptService/World/WorldDiagnostics.lua`
- `WORLD_INTELLIGENCE.md`
- `WORLD_MODEL.md`
- `ZONE_PROFILES.md`
- `ROOM_PROFILES.md`
- `WORLD_AFFORDANCES.md`
- `LONDON_ENGINE.md`
- `ROADMAP.md`
- `TASKS.md`
- `default.project.json`

## Issues Found

- Registry reads and writes used shallow clones, which could let future callers mutate nested profile policy tables after registration.
- Policy validation covered lighting brightness but did not fully validate audio, monster, puzzle, boolean, bias, and tag fields.
- Duplicate registrations could overwrite existing profiles silently.
- Unknown puzzle defaults did not explicitly protect puzzle focus.
- Diagnostics did not summarize policy safety or expose validation state.
- Roadmap and task files still had legacy duplicate Phase 9/10 headings that could confuse future work.

## Fixes Made

- Added bounded deep-copy protection for registered profiles, returned profiles, and recent world contexts.
- Rejected duplicate profile registration to avoid accidental content replacement.
- Strengthened validation for lighting, audio, monster, puzzle, tag, affordance, room, atmosphere, and zone policies.
- Enforced safety alignment: safe rooms cannot allow monster reveal, chase start, or blackout; puzzle rooms must protect active puzzle focus; monster/chase affordances must match monster policy.
- Kept unknown spaces conservative: no monster reveal, no chase start, no blackout, and no major puzzle interruption.
- Improved diagnostics with profile counts, recent context count, validation state, and policy safety summary.
- Clarified that affordances are permissions and context hints, never direct actions.
- Fixed roadmap/task numbering so Phase 10 is World Intelligence and later phases move forward consistently.

## Remaining Risks

- World Intelligence is passive and not lifecycle-registered yet, so diagnostics are available by module call rather than automatic SnapshotManager registration.
- No real Chapter 1 profiles exist yet, by design.
- Future replacement APIs should be reviewed carefully before allowing profile updates after registration.
- Future Studio binders must not derive trusted zone identity from client-owned state.

## Integration Guidance

Observation Engine should include reliable `zoneId`, `zoneKind`, and tags in observations. If the zone is unknown, future systems must consume the conservative fallback context.

Environment Director should use world context to suppress unsafe reactions, especially in safe rooms, puzzle rooms, transitions, and unknown zones.

Future Lighting Director should consume `lightingPolicy` before dimming, flickering, misleading direction, or considering blackout.

Future Audio Director should consume `audioPolicy`, atmosphere profile, and room personality before whispers, heartbeat, breathing, fake sounds, or silence drops.

Future Monster Director should consume `monsterPolicy` and still request approval through DirectorCoordinator. World affordances never create Monster AI behavior.

Simulation Framework may register synthetic profiles to prove policy behavior, but Simulation must remain disabled by default and must not mutate Workspace.

## Review Decision

Phase 10 remains a contract/data-model layer only. No Chapter 1 content, Monster AI, final UI/art/scares, client remotes, or Workspace mutation were added.
