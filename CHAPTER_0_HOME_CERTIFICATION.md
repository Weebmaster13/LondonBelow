# Chapter 0 Home Runtime Certification Evidence

Phase 109, Phase 110, Phase 111, Phase 112, Phase 113, and Phase 114 runtime
certification evidence is split into truthful execution classes.

## Static Checks

- Luau formatting and static analysis.
- Rojo sourcemap and build.
- Phase-delta forbidden API scan.
- Runtime-surface executable scan.
- Bootstrap, Governance, diagnostics, snapshot provider, and remote contract review.
- Static inspection of self-check definitions.
- Phase 110 hardening inspection for closed schemas, bounded state histories,
  cycle-safe serialization, owned-root reset safety, and connection cleanup posture.
- Phase 111 atmospheric feedback inspection for canonical feedback definitions,
  deterministic interaction references, bounded history, existing feedback delivery,
  diagnostics posture, snapshot isolation, and banned-surface absence.
- Phase 112 environmental reaction inspection for canonical reaction definitions,
  deterministic interaction and target references, bounded history, scoped
  owned-Workspace attribute mutation, diagnostics posture, snapshot isolation, and
  banned-surface absence.
- Phase 113 environmental reaction hardening inspection for exact reaction ids,
  exact target references, exact attribute names, metadata attribute prefix,
  scalar-only attribute projection, diagnostics posture, snapshot schema evidence,
  and Phase 112 regression protection.
- Phase 114 atmospheric progression inspection for canonical stage definitions,
  canonical transition definitions, exact feedback and reaction references, bounded
  per-player progression history, optional modifier behavior, diagnostics posture,
  snapshot isolation, and banned-surface absence.
- Phase 115 atmospheric progression hardening inspection for exact centralized
  stage definitions, transition definitions, initial stage id, reference bindings,
  required-interaction sequences, optional-modifier identity, drift rejection,
  out-of-order no-mutation state behavior, diagnostics posture keys, snapshot
  schema evidence, and Phase 114 regression protection.

## Local Executable Checks

`npm run london:selfchecks:phase109` and `npm run london:selfchecks:phase110`
detect local bundled Luau, Lune, Roblox CLI, or no standalone runtime.

When no standalone runtime is available, it records `Runtime unavailable - Roblox Studio required` and does not report totals or zero failures.

## Roblox Studio Runtime Checks

The Phase 109 authoritative runtime suite is
`ServerScriptService.Chapter0Home.Studio.Phase109SelfCheckRunner`.

It remains gated by `RunService:IsStudio()` and explicit Workspace attribute `LondonPhase109RunSelfChecks = true`.

The Phase 110 authoritative runtime-certification suite is
`ServerScriptService.Chapter0Home.Studio.Phase110CertificationRunner`.

It remains gated by `RunService:IsStudio()` and explicit Workspace attribute
`LondonPhase110RunSelfChecks = true`.

Both phase entry points use the shared
`ServerScriptService.Chapter0Home.Studio.Chapter0HomeStudioSelfCheckRunner`
implementation so the runtime suite is not duplicated.

Phase 110 certification output distinguishes setup failures from assertion failures,
prints exact totals, verifies Chapter0Home checks, PlayerExperience remote contract
checks, RemoteManager adoption/idempotence checks, and required upstream regression
checks, then restores temporary Chapter0Home runtime state.

Production Certification requires this suite to execute and report final `PASS` with
zero failures. Until that happens, Phase 109, Phase 110, and Phase 111 remain
Production Candidate milestones. Phase 112 also remains Production Candidate until
its reaction path is executed by the authoritative Roblox Studio runtime suite.
Phase 113 remains Production Candidate until its hardening checks execute in the
same authoritative runtime.
Phase 114 remains Production Candidate until its atmospheric progression checks
execute in the same authoritative runtime.
Phase 115 remains Production Candidate until its hardened atmospheric progression
checks execute in the same authoritative runtime.

## Certification Boundary

No runtime execution result may be inferred from static inspection, committed implementation, successful build, or unavailable runtime detection.
## Phase 116 Certification Status

Phase 116 is a Production Candidate. Certification requires implementation,
formatting, static validation, build verification, phase-delta forbidden-surface
scan, runtime-surface scan, generated artifact cleanup, self-check definition
review, commit, push, remote verification, and authoritative Roblox Studio runtime
self-check execution.

The phase cannot be marked Production Certified until
`Chapter0HomeCoordinator.runSelfChecks()` and required upstream regression
self-checks execute in Roblox Studio through the Studio-gated runner and report
final `PASS` with zero failures. No deferred runtime result may be inferred from
static source inspection.

Phase 116 certification boundaries: Chapter0Home remains authoritative for source
state; Observation Runtime remains read-only toward Chapter0Home; all observation
facts are canonical, bounded, server-authoritative, and published through existing
Observation Runtime boundaries only; no new remotes, hidden client authority,
persistence, analytics, telemetry, Monster AI, combat, inventory, save execution,
cutscenes, final audiovisual presentation, or Chapter 1 content are introduced.

## Phase 117 Certification Status

Phase 117 is a Production Candidate. Certification requires all Phase 117 static
validation, build verification, phase-delta scans, runtime-surface review,
self-check definition review, commit, push, remote verification, and authoritative
Roblox Studio runtime self-check execution.

The phase cannot be marked Production Certified until the Studio-gated Chapter 0
Home self-check runner executes `Chapter0HomeCoordinator.runSelfChecks()` and
required upstream regressions with final `PASS` and zero failures. Static source
inspection cannot certify deferred runtime checks.

## Phase 118 Runtime Certification Review

Phase 118 adds the Studio-only certification review entry point:

```text
ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner
```

The runner requires `RunService:IsStudio()` and explicit Workspace attribute
`LondonPhase118RunCertification = true`. It refuses missing-gate execution,
production-server execution, and concurrent duplicate runs. It clears only the
Phase 118 gate and active-run marker during cleanup.

The deterministic result schema records schema version, phase identity, runner id,
runtime, Studio posture, gate posture, start and finish timestamps, duration,
status, separated setup/assertion/cleanup/upstream statuses, executed and skipped
suites, totals, failures by category, runtime-unavailable posture, production
certification decision, evidence id, and next action. Production certification is
allowed only when authoritative Studio execution runs required suites, reports zero
failures, completes cleanup, and validates structured evidence.

When Roblox Studio execution is unavailable, Phase 118 remains Production Candidate
and reports runtime execution as deferred.

## Phase 119 Certification Hardening

Phase 119 hardens the Phase 118 certification path and does not certify deferred
runtime execution. `Phase118CertificationContract` is the source of truth for
schema version, phase identity, runner id, runtime name, gate attributes, required
suite ids and ordering, status values, result fields, failure fields, next-action
values, diagnostic posture keys, snapshot schema names, certification
requirements, and bounded result limits.

`Phase118CertificationRunner` uses the contract's single certification decision
function. Production certification is true only when Studio runtime, explicit gate,
setup pass, assertion pass, cleanup pass, upstream pass, all required suites
executed, zero failed checks, empty failure arrays, no blocking warnings, valid
evidence posture, and final `passed` status are all present.

Phase 119 remains Production Candidate until authoritative Roblox Studio execution
actually produces valid passing evidence.
