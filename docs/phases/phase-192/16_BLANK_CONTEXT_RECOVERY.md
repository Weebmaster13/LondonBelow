# Phase 192 - Blank Context Recovery
## Ownership
Repository `Weebmaster13/LondonBelow`; pushed baseline `2685d97ff0a15bd82ea1fdc137c112c40397f42c`. Read AGENTS, engine constitution/governance, Phase 191/192 docs, every client Rendering module, animation automation/evidence, completion report, and phase-state before editing.

Recovery order:

1. Verify the checkout descends from the Phase 191 state commit above. Read `AGENTS.md`, `ENGINE_CONSTITUTION.md`, `ENGINE_GOVERNANCE.md`, engine context, roadmap, tasks, phase-state, and runtime evidence.
2. Read `RobloxGuiRenderingRuntime.lua`, every Phase 192 animation/motion module, the instance registry, rendering catalog, and value decoder as one revision-owned boundary.
3. Verify the current Phase 192 implementation, validation, and state commits recorded by the completion report and `automation/state/phase-state.json`.
4. Run Phase 192 self-check (expected 278), then Phases 184–191 (expected 1,243). Expected combined total is 1,521.
5. Run Node syntax, StyLua format/check, Selene, Rojo sourcemap/build, architecture generate/check, `git diff --check`, repository checks, and the forbidden scan where available. Record unavailable tools truthfully rather than turning absence into a pass.
6. Keep runtime `executionBlocked` unless authoritative Roblox Studio evidence supplies the exact 42 passing cases, correct phase, `authoritative: true`, and a non-empty Studio run ID.

Critical call order: successful rendering commit -> animation reconciliation -> prior animation cancellation -> generation advance. Unmount cancellation precedes tree destruction. Shutdown cleans the visual tree and then closes the animation runtime. Failed/idempotent reconciliation and PlayerGui remount preserve current transitions.

Critical invariants: exact active revision; matching runtime contract identity; rendering/animation allowlist intersection; bounded goals, timing, repeats, IDs, active records, audits, and failures; capture all originals before sorted supersession; completion connection cleanup; reverse rollback for failed immediate apply; no custom frame scheduler; copied bounded diagnostics.
## Non-Ownership
Animation is local presentation only. Preserve exact target revision/identity, allowlists, budgets, supersession ordering, cancellation restoration, motion preferences, reconciliation cleanup, diagnostics, and forbidden surfaces.
## Certification Boundary
Phase 108 stays certified. Phase 192 stays Candidate without complete authoritative Studio evidence. Next recommended Phase 193 is animation/transition production hardening and Studio certification.
