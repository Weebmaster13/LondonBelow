# Chapter 0 Home Runtime Certification Evidence

Phase 109 and Phase 110 runtime certification evidence is split into truthful
execution classes.

## Static Checks

- Luau formatting and static analysis.
- Rojo sourcemap and build.
- Phase-delta forbidden API scan.
- Runtime-surface executable scan.
- Bootstrap, Governance, diagnostics, snapshot provider, and remote contract review.
- Static inspection of self-check definitions.
- Phase 110 hardening inspection for closed schemas, bounded state histories,
  cycle-safe serialization, owned-root reset safety, and connection cleanup posture.

## Local Executable Checks

`npm run london:selfchecks:phase109` detects local bundled Luau, Lune, Roblox CLI, or no standalone runtime.

When no standalone runtime is available, it records `Runtime unavailable - Roblox Studio required` and does not report totals or zero failures.

## Roblox Studio Runtime Checks

The authoritative runtime suite is `ServerScriptService.Chapter0Home.Studio.Phase109SelfCheckRunner`.

It remains gated by `RunService:IsStudio()` and explicit Workspace attribute `LondonPhase109RunSelfChecks = true`.

Production Certification requires this suite to execute and report final `PASS` with
zero failures. Until that happens, Phase 109 and Phase 110 remain Production
Candidate milestones.

## Certification Boundary

No runtime execution result may be inferred from static inspection, committed implementation, successful build, or unavailable runtime detection.
