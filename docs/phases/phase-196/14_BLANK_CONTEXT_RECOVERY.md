# Blank-Context Recovery

## Ownership

The authoritative remote baseline before this phase is pushed Phase 195 state commit `2cbfdbe644ae9b1e6ab022bb42847dd1bfed04ec`. Phase 196 deliberately replaces the previously recommended declarative-component micro-phase with a player-facing vertical slice because the project needed game content, cohesion, and a quality target.

Recover the system in this order:

1. Read `Chapter196VerticalSliceConfig.lua`. Preserve the exact nine-objective order and the entrance, archive, and ritual checkpoints.
2. Read `Chapter196Types.lua` and `Chapter196State.lua`. State is server-only; objective progress is party-shared while inventory and checkpoints remain attributable by user ID.
3. Read `Chapter196WorldBuilder.lua`. It owns only the runtime folder named by `Config.RootName`, the `BlackwaterAtmosphere`, and a reversible snapshot of the Lighting values it changes.
4. Read `Chapter196VisualPlanBridge.lua` and `Chapter196Coordinator.lua`. The required transaction is validate, create/validate/seal/prepare/apply/commit the Phase 184 abstract visual patch, grant an item if applicable, apply the authored world reaction, publish narrative/discovery state, emit interaction/objective observations, advance the objective, update the Horror Director phase, and publish replicated state.
5. Read `Chapter196HudController.client.lua`. It reads Workspace attributes and must never call `FireServer` or `InvokeServer`. Preserve its rendering contracts, localized/responsive presentation, theme/animation integrity, accessible live regions, and generation-fenced Case File action. The journal is local presentation over server-earned discovery/relic truth.
6. Inspect the Bootstrap registration and the Phase 196 Governance contract. Dependencies must resolve to exact governed system names.
7. Run the Phase 196 Node self-check, Phase 184–196 regressions, architecture generation/check, `git diff --check`, StyLua, Selene, Rojo sourcemap/build, and forbidden-surface checks wherever those binaries are truly available.
8. Keep runtime evidence `executionBlocked` unless one authoritative Studio artifact has phase 196, a non-empty Studio run ID, at least twelve playthrough minutes, and exactly the 80 required passed cases.

The playable call flow is:

`ProximityPrompt.Triggered -> validateInteraction -> State/item mutation -> authored beat -> ObservationService.observe -> State.advanceObjective -> HorrorDirector.setChapterPhase -> replicated attributes -> GUI contract revision -> localization/theme/animation -> integrity verification`.

Failure handling is fail-closed. Wrong order, duplicates, range violations, missing party seal, world build failure, and incomplete evidence cannot advance chapter truth. Death emits `Objective.Failed`; CharacterAdded restores the player's latest checkpoint. Shutdown disconnects every tracked prompt/player/humanoid connection, destroys the owned world and atmosphere, restores Lighting, clears state and counters, and releases references.

## Non-Ownership

Do not shrink the next phase back into invisible micro-infrastructure. Do not move objective, inventory, checkpoint, or escape truth to the client. Do not introduce an autonomous monster that bypasses the Monster or Horror Director. Do not label primitive runtime geometry as final production art, and do not fabricate Studio, formatting, lint, or build results.

## Certification Boundary

Phase 196 remains a Production Candidate until its exact Studio evidence succeeds. Phase 108 remains Production Certified.

Next: Phase 197 – Blackwater Descent Production Art, Monster Encounter, and Studio Certification. Its definition of done is a materially better game: production environment/audio assets, a governed monster encounter, a tuned escape climax, verified solo and multiplayer playthroughs, performance/leak results, accessibility review, and authoritative Studio certification evidence.
