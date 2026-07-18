# London Below Phase 149 Total AAA Studio Audit And Remediation Mission

## Mission

Act as the Lead Technical Director, Principal Engine Architect, Lead Gameplay
Engineer, Lead Horror Designer, Lead Narrative Designer, Build Engineer, QA
Director, Roblox Studio Automation Engineer, and Release Engineer for London
Below.

Your job is to review the entire repository from Phase 1 through Phase 149,
compare it against the London Engine Constitution and the London Below Bible,
determine whether the project is genuinely becoming a coherent AAA
psychological horror game, repair only high-confidence technical drift, validate
the result, and produce durable evidence.

This is not permission to rewrite the game. This is permission to perform one
supervised, evidence-based studio audit and safe remediation pass.

## Duration Expectation

This is expected to be a long-running engineering mission. Treat 30 minutes as
the minimum review-depth target, not as a timer. Do not sleep, stall, or add
artificial waiting. Instead, continue performing substantive repository analysis
until every required pass and evidence artifact below is complete.

The mission is not complete simply because:

- builds pass;
- lint passes;
- one audit report exists;
- documentation looks synchronized;
- Phase 149 has been reviewed;
- the first safe remediation pass is complete.

Continue iterating until all 30 required passes, all final sweeps, all evidence
reports, all validation commands, all reachable Studio execution attempts, and
all safe remediations are complete or a genuine blocker prevents further
progress.

Do not optimize for speed. Optimize for completeness, traceability, and
truthfulness.

## Repository

Work only in:

```text
C:\Users\nzomo_dx4jmc8\Documents\GitHub\LondonBelow
```

Do not use any copy folder.

## Current Certification Truth

- Latest Production Certified phase: Phase 108.
- Latest Production Candidate phase: Phase 149.
- Phase 109 through Phase 149 remain Production Candidates unless authoritative
  runtime evidence proves otherwise.
- Do not promote any phase to Production Certified without actual required
  validation, runtime self-check execution, forbidden-surface scan, and
  certification authority approval on the exact commit.
- Do not fabricate GitHub links, commits, validation results, Roblox Studio
  results, self-check totals, runtime evidence, or certification decisions.

## Non-Negotiable Safety Rules

You must not:

- Rewrite Git history.
- Force push.
- Reset hard.
- Clean the repository destructively.
- Delete branches, tags, source trees, docs, Bible files, or generated evidence.
- Publish a Roblox place.
- Spend Robux.
- Touch live DataStores.
- Add analytics, telemetry, monetization, external services, or secrets.
- Weaken tests or validation to make the audit pass.
- Replace the London Below Bible.
- Change creative canon without an explicit human decision.
- Implement Chapter 1.
- Add Monster AI, combat, inventory, save writes, networking, remotes, or
  gameplay authority unless a later approved phase explicitly requires it.
- Claim static checks are Roblox runtime evidence.
- Treat Studio discovery as Studio execution.

## Branch And Commit Policy

1. Start from a clean `main` branch matching `origin/main`.
2. Create or switch to a protected review branch:

```text
codex/phase-149-total-aaa-review
```

3. Produce audit reports before code remediation.
4. Commit only when:
   - the audit reports are complete;
   - safe remediation is complete;
   - validation has run truthfully;
   - no unresolved blocker is hidden.
5. Use separated commits when useful:
   - one audit evidence commit;
   - one safe remediation commit;
   - one validation/report finalization commit.
6. Do not push unless the user or launcher explicitly authorizes pushing.

## Required Audit Output Directory

Create:

```text
docs/audits/phase-149-total-review/
```

Produce or update these files:

```text
EXECUTIVE_SUMMARY.md
PHASE_LEDGER_001_149.md
ARCHITECTURE_MAP.md
DEPENDENCY_GRAPH.md
BIBLE_TRACEABILITY_MATRIX.md
AAA_HORROR_READINESS_SCORECARD.md
GAMEPLAY_READINESS_REVIEW.md
NARRATIVE_READINESS_REVIEW.md
HORROR_SYSTEMS_REVIEW.md
ROBLOX_STUDIO_EXECUTION_EVIDENCE.md
VALIDATION_EVIDENCE.md
GITHUB_AUDIT.md
DOCUMENTATION_DRIFT.md
GOVERNANCE_DRIFT.md
BOOTSTRAP_REGISTRATION_REVIEW.md
SCHEMA_LIFECYCLE_REVIEW.md
SELF_CHECK_COVERAGE_REVIEW.md
TECHNICAL_DEBT_REGISTER.md
RISK_REGISTER.md
REMEDIATION_LOG.md
REMEDIATION_ROADMAP.md
PHASE_149_GO_NO_GO.md
MANUAL_VISUAL_QA_CHECKLIST.md
REPOSITORY_FILE_INVENTORY.md
REPOSITORY_KNOWLEDGE_GRAPH.md
SYMBOL_INDEX.md
MODULE_DEPENDENCY_GRAPH.md
PUBLIC_API_CATALOG.md
RUNTIME_STATE_TRACE.md
STATE_LIFECYCLE_MATRIX.md
DETERMINISM_REPORT.md
VALIDATION_TRACEABILITY.md
SELFCHECK_COVERAGE.md
DOCUMENTATION_ACCURACY.md
PERFORMANCE_ARCHITECTURE.md
SECURITY_REVIEW.md
VERTICAL_SLICE_PLAN.md
STUDIO_SCALABILITY.md
LONG_TERM_ROADMAP_ANALYSIS.md
EXECUTIVE_GREENLIGHT_REVIEW.md
FINAL_SWEEP_REGISTER.md
AUDIT_MANIFEST.json
```

Every report must distinguish evidence, inference, and recommendation.

## Required 30-Pass Protocol

The audit must perform these passes in order. If a pass finds a blocker, record
the blocker and continue with every later pass that can still be completed
safely.

1. Repository safety pass: verify working tree, branch, remote, generated
   artifacts, ignored files, and user changes.
2. Instruction hierarchy pass: read every applicable `AGENTS.md` and permanent
   engineering rule.
3. Canon pass: read the entire London Below Bible and record canon-critical
   constraints.
4. Engine constitution pass: read and summarize constitutional runtime laws.
5. Phase ledger pass: reconstruct Phase 1 through Phase 149 from docs and Git.
6. Git history pass: inspect commit progression, pivots, duplicated work, and
   certification claims.
7. Source inventory pass: enumerate every source, automation, config, Markdown,
   JSON, TOML, project, and script file.
8. Module symbol pass: index every exported module, public function, public
   field, imported module, and dependency.
9. Dependency graph pass: build module and subsystem dependency graphs.
10. Bootstrap pass: verify registration order, dependency names, provider names,
    and missing/stale registrations.
11. Governance pass: verify contract ownership, non-ownership, docs, diagnostics,
    snapshots, cleanup, failure modes, and certification boundaries.
12. Schema pass: verify field names, required fields, enum names, exact-schema
    enforcement, limits, and doc/code agreement.
13. Lifecycle pass: verify initial states, terminal states, legal transitions,
    skipped transition rejection, terminal mutation rejection, shutdown cleanup,
    and failure state classification.
14. State trace pass: trace every runtime state from creation through mutation,
    publication, diagnostics, snapshots, audit, serialization, and cleanup.
15. Determinism pass: review ordering, clocks, random sources, filesystem order,
    table iteration, serialization order, and platform-sensitive assumptions.
16. Diagnostics pass: verify health-only diagnostics, lowerCamelCase posture
    keys, provider names, and no runtime evidence overclaim.
17. Snapshot pass: verify snapshot provider names, isolation, deep copies,
    bounded history, and no mutable publication.
18. Audit pass: verify append-only records, deterministic order, source
    attribution, no secret leakage, and no certification overclaim.
19. Self-check pass: map every self-check definition to execution path,
    categories, expected totals where documented, blocked runtime status, and
    upstream regressions.
20. Validation traceability pass: map every documented invariant to validation,
    self-check, diagnostics, and runtime evidence status.
21. Documentation accuracy pass: read every Markdown file and flag stale paths,
    stale phase numbers, provider drift, maturity drift, and unsupported claims.
22. Security pass: inspect filesystem, process execution, dynamic execution,
    environment variables, networking, Roblox services, serialization, and
    credential boundaries.
23. Performance architecture pass: inspect complexity, allocation patterns,
    copying, recursion, hot loops, cache opportunities, cleanup, and memory
    ownership without inventing benchmark data.
24. Bible traceability pass: map horror, narrative, world, entity, player,
    memory, identity, and Chapter 0 expectations to implemented systems.
25. Gameplay readiness pass: determine what a player can actually do today and
    what is still infrastructure-only.
26. Horror readiness pass: score atmosphere, pacing, tension, observation,
    Director support, environmental storytelling, audio/lighting readiness, and
    monster-readiness without pretending final assets exist.
27. Roblox Studio execution pass: detect Studio and attempt documented
    repository-supported execution only if prerequisites are actually present.
28. Safe remediation pass: fix only high-confidence technical drift and record
    every change.
29. Revalidation pass: rerun all available validation and forbidden-surface
    scans after remediation.
30. Final consistency pass: re-read generated reports, updated files, phase
    state, roadmap, tasks, master context, and Git status to ensure no report
    contradicts evidence.

After pass 30, perform three final sweeps:

- Sweep A: search for any remaining false Production Certification or runtime
  evidence implication.
- Sweep B: search for any missed provider, bootstrap, governance, diagnostics,
  snapshot, audit, schema, lifecycle, or documentation drift.
- Sweep C: search for anything a senior external studio would reject before
  continuing development.

Record the results in `FINAL_SWEEP_REGISTER.md`.

## Stage 1: Canon And Repository Context

Read every applicable `AGENTS.md`, then read:

- `ENGINE_CONSTITUTION.md`
- `ENGINE_GOVERNANCE.md`
- `LONDON_ENGINE.md`
- `LONDON_ENGINE_MASTER_CONTEXT.md`
- `ROADMAP.md`
- `TASKS.md`
- `ARCHITECTURE.md`
- `SYSTEMS.md`
- `AI_DESIGN.md`
- every file under `LONDON_BIBLE/`
- package scripts and automation configuration
- Governance registry
- Bootstrap registrations
- current `automation/state/phase-state.json`

Build a concise internal model before making any changes.

## Stage 2: Git And Phase Reconstruction

Inspect local Git history and phase progression from Phase 1 through Phase 149.

For `PHASE_LEDGER_001_149.md`, record:

- phase number;
- phase name;
- commit hash when discoverable;
- implementation type;
- Production Certified or Production Candidate status;
- primary subsystem;
- whether documentation, governance, bootstrap, diagnostics, snapshots, and
  self-checks appear synchronized;
- notable pivots, abandoned surfaces, duplicate authorities, and open risks.

If GitHub access is available, compare:

- local `main`;
- `origin/main`;
- open branches;
- Actions or check status when available;
- remote drift;
- recent pushes.

If GitHub access is not available, state that clearly in `GITHUB_AUDIT.md`.

## Stage 3: Source And Architecture Audit

Read every source file under `src` and every automation module under
`automation`.

Build `ARCHITECTURE_MAP.md` and `DEPENDENCY_GRAPH.md` covering:

- runtime ownership;
- bootstrap order;
- provider names;
- diagnostics providers;
- snapshot providers;
- schemas and lifecycle states;
- validation boundaries;
- audit boundaries;
- forbidden runtime surfaces;
- read-only upstream dependencies;
- writable state owners;
- client/server authority split.

Build `REPOSITORY_FILE_INVENTORY.md`, `REPOSITORY_KNOWLEDGE_GRAPH.md`,
`SYMBOL_INDEX.md`, `MODULE_DEPENDENCY_GRAPH.md`, and `PUBLIC_API_CATALOG.md`.

For every exported module, record:

- owner;
- responsibilities;
- public API;
- private helpers if visible;
- upstream callers;
- downstream consumers;
- documentation references;
- validation references;
- self-check references;
- lifecycle participation;
- diagnostics provider;
- snapshot provider;
- audit provider;
- evidence classification;
- certification boundary.

Find:

- duplicate systems;
- abandoned systems;
- dead registrations;
- docs/code drift;
- schema field drift;
- lifecycle naming drift;
- provider naming drift;
- lowerCamelCase posture drift;
- hidden client authority;
- forbidden APIs;
- runtime evidence wording that is stronger than actual evidence;
- certification wording that exceeds actual evidence.

## Stage 3.5: Runtime State And Determinism Audit

Trace every runtime state object from creation through publication.

For every state object determine:

- creator;
- first mutation;
- final mutation;
- publication point;
- consumers;
- destruction point;
- cleanup behavior;
- serialization behavior;
- snapshot inclusion;
- audit inclusion;
- diagnostics inclusion.

Detect:

- mutable publication;
- mutable snapshots;
- hidden mutations;
- ownership violations;
- duplicated state;
- stale state;
- leaked references;
- non-deterministic ordering.

Write `RUNTIME_STATE_TRACE.md` and `STATE_LIFECYCLE_MATRIX.md`.

Evaluate every deterministic claim. For every subsystem determine:

- why it claims determinism;
- what assumptions are required;
- whether ordering is guaranteed;
- whether maps are iterated deterministically;
- whether clocks are used;
- whether random numbers are used;
- whether filesystem ordering matters;
- whether platform differences matter.

Classify each subsystem:

- Proven deterministic;
- Probably deterministic;
- Not proven;
- Non-deterministic.

Write `DETERMINISM_REPORT.md`.

## Stage 3.6: Validation And Self-Check Traceability

Build `VALIDATION_TRACEABILITY.md`.

For every validation rule determine:

- implementation;
- documentation;
- self-check;
- diagnostics relationship;
- runtime evidence relationship;
- certification relationship.

Mark each rule:

- documented only;
- implemented only;
- fully covered;
- partially covered;
- missing.

Build `SELFCHECK_COVERAGE.md`.

For every self-check determine:

- registration;
- discoverability;
- execution path;
- expected output;
- failure classification;
- cleanup;
- determinism;
- runtime evidence classification;
- upstream regression coverage.

## Stage 4: London Bible Traceability

Compare the repository to the Bible and answer:

- Does the current engine support the intended psychological horror experience?
- Are the creative pillars present in runtime architecture?
- Does Chapter 0 Home have enough playable, testable shape?
- Is the project over-investing in infrastructure while under-building playable
  horror?
- What would Naughty Dog, Frictional Games, Bloober Team, or Remedy criticize
  first if they inherited this repository tomorrow?

Write:

- `BIBLE_TRACEABILITY_MATRIX.md`
- `AAA_HORROR_READINESS_SCORECARD.md`
- `GAMEPLAY_READINESS_REVIEW.md`
- `NARRATIVE_READINESS_REVIEW.md`
- `HORROR_SYSTEMS_REVIEW.md`
- `VERTICAL_SLICE_PLAN.md`

Do not rewrite the Bible. Record creative gaps as approval-required findings.

## Stage 5: Roblox Studio Execution Attempt

Roblox Studio evidence is valuable only if it is real.

First detect:

1. newest local `RobloxStudioBeta.exe`;
2. Rojo build capability;
3. documented local Studio command-line support for scripted execution;
4. any repository-supported Studio test harness;
5. output file capture support;
6. ability to close Studio after execution.

If every prerequisite is present, build a temporary place with Rojo and attempt
a Studio command-line test using only documented locally supported flags. A
candidate command shape is:

```powershell
RobloxStudioBeta.exe `
  --task RunScript `
  --localPlaceFile "<built-place.rbxlx>" `
  --runScriptFile "<studio-audit-harness.luau>" `
  --outputFile "<studio-results.log>" `
  --quitAfterExecution
```

Do not assume this command is supported just because it is listed here. Verify
support by actual command behavior and captured output.

The generated Studio harness may only inspect and execute safe test entry
points. It must not publish places, write DataStores, call HTTP, mutate live
services, spend Robux, or depend on player accounts.

The Studio harness should attempt, where supported:

- module loading;
- Bootstrap registration smoke test;
- provider availability;
- diagnostics provider shape checks;
- snapshot provider shape checks;
- Phase 109 through Phase 149 self-check entry points;
- canonical blocked-runtime truth;
- shutdown/cleanup checks;
- Run mode smoke tests;
- Play mode smoke tests only if safely supported;
- conservative multiplayer smoke tests only if repository-supported.

If Studio execution is unavailable or blocked, record the exact blocker in
`ROBLOX_STUDIO_EXECUTION_EVIDENCE.md` and do not claim runtime evidence.

If Studio executes, preserve:

- exact executable path;
- command;
- exit code;
- stdout;
- stderr;
- output file content;
- duration;
- generated harness path;
- generated place path;
- cleanup result;
- pass/fail status.

## Stage 6: Repository Validation

Run every available validation truthfully:

```powershell
node --check automation/*.mjs
npm run london:status
npm run london:check
stylua src
stylua --check src
selene src
rojo sourcemap default.project.json --output sourcemap.json
rojo build default.project.json --output rojo-verify.rbxlx
git diff --check
```

Delete generated `sourcemap.json` and `rojo-verify.rbxlx` after validation.

Run all available self-check commands in `package.json`. If a command is blocked
because no runtime exists, record it as blocked, not failed and not passed.

Run forbidden-surface scans over:

- current phase runtime surfaces;
- all executable Lua under `src`;
- all automation modules;
- documentation claims that mention runtime evidence or certification.

Record exact command, exit code, stdout, stderr, duration, and pass/fail/block
status in `VALIDATION_EVIDENCE.md`.

## Stage 6.5: Documentation, Performance, Security, And Scalability

Read every Markdown file and compare claims against implementation.

Flag:

- outdated examples;
- incorrect paths;
- incorrect module names;
- incorrect provider names;
- stale lifecycle diagrams;
- obsolete phase references;
- incorrect next-phase references;
- mismatched runtime maturity;
- documentation that overstates implementation;
- documentation that understates blockers.

Write `DOCUMENTATION_ACCURACY.md`.

Without inventing benchmarks, inspect structural performance:

- algorithmic complexity;
- repeated allocations;
- deep recursion;
- unnecessary copying;
- duplicate traversal;
- large hot-path loops;
- cache opportunities;
- memory ownership;
- cleanup discipline.

Clearly distinguish measured performance from predicted structural concerns.
Write `PERFORMANCE_ARCHITECTURE.md`.

Review security boundaries around:

- filesystem access;
- process execution;
- networking;
- HTTP;
- Roblox services;
- credentials;
- environment variables;
- serialization;
- dynamic execution;
- generated artifacts.

Classify each issue by severity and confidence. Write `SECURITY_REVIEW.md`.

Evaluate production scalability for:

- one developer;
- five developers;
- ten developers;
- twenty developers.

Identify risks in ownership, merge pressure, documentation, testing, code
organization, onboarding, and release safety. Write `STUDIO_SCALABILITY.md`.

Project the roadmap forward through the next 50 planned phases, or as many as
the repository defines. Identify dependency consistency, sequencing risks,
circular planning, redundant milestones, opportunities to merge phases, and
blockers that should be advanced. Write `LONG_TERM_ROADMAP_ANALYSIS.md`.

## Stage 7: Safe Remediation Rules

You may automatically repair only high-confidence non-creative drift:

- documentation drift;
- spelling and terminology inconsistencies;
- provider name mismatches;
- bootstrap registration mismatches;
- governance registry omissions;
- diagnostics/snapshot naming drift;
- exact schema docs that contradict code;
- validation docs that contradict code;
- phase-state truthfulness errors;
- stale next-phase wording;
- generated artifact cleanup;
- broken local references in docs;
- missing audit report files;
- missing validation evidence formatting;
- obvious self-check coverage documentation gaps.

You must not automatically repair:

- creative canon;
- story beats;
- monster design;
- final art/audio/animation direction;
- Chapter 1 content;
- networking design;
- persistence design;
- monetization;
- live services;
- large subsystem rewrites;
- runtime execution expansion.

For those, create approval-required findings in `REMEDIATION_ROADMAP.md`.

## Stage 8: Professional Critique

Add a section titled:

```text
Studio Inheritance Critique
```

Answer plainly:

- What would a top horror studio criticize first?
- What is the most serious architecture risk?
- What is the most serious production risk?
- What is the most serious gameplay risk?
- What is the most serious narrative risk?
- What is the most serious QA risk?
- What one thing would most improve player-facing horror next?

Keep criticism evidence-based and actionable.

Write `EXECUTIVE_GREENLIGHT_REVIEW.md` as if presenting to an internal studio
greenlight committee. Include independent review notes for:

- engine;
- gameplay;
- horror;
- narrative;
- QA;
- performance;
- production;
- security;
- tooling.

Each reviewer must answer:

- greatest strengths;
- highest-priority risks;
- what should not change;
- what should change immediately;
- whether the architecture is sustainable;
- whether creative direction is supported by the engine;
- whether the repository is ready for continued implementation.

## Stage 9: Final Decision

Write `PHASE_149_GO_NO_GO.md` with exactly one decision:

- `GO`
- `CONDITIONAL GO`
- `HOLD`

Use:

- `GO` only if architecture, docs, validation, and evidence are internally
  consistent and no blocking risks remain.
- `CONDITIONAL GO` if the repository can proceed but has named conditions.
- `HOLD` if continuing would likely compound architecture, gameplay, or
  evidence problems.

The decision must include:

- certification truth;
- runtime evidence status;
- validation status;
- GitHub status;
- safe remediations performed;
- blockers;
- next recommended remediation batches;
- next recommended engine phase.

## Stage 10: Final Report

The final response must include:

- branch name;
- commit hashes created, if any;
- whether anything was pushed;
- exact reports written;
- validation summary;
- Studio execution status;
- remediation summary;
- GO/CONDITIONAL GO/HOLD decision;
- top five findings;
- next safe action.

If no commit was created, say so. If no push occurred, say so. Do not include a
GitHub commit link unless a commit was pushed and the URL was verified.
