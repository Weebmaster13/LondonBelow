# Phase 149 Total AAA Studio Audit

This directory contains the repository-local mission prompt for the halfway
London Below AAA studio audit.

The mission is intentionally stronger than a normal audit:

- treat 30 minutes as the minimum review-depth target, without fake waiting;
- complete 30 explicit review passes plus three final sweeps;
- reconstruct Phase 1 through Phase 149;
- compare code and docs against the London Engine Constitution;
- trace implementation against the London Below Bible;
- inspect source, automation, Bootstrap, Governance, diagnostics, snapshots,
  schemas, lifecycle rules, and self-check coverage;
- build a repository file inventory, symbol index, public API catalog, runtime
  state trace, determinism report, validation traceability matrix, documentation
  accuracy report, performance architecture review, security review, scalability
  review, and vertical-slice plan;
- attempt Roblox Studio execution only when a supported local command path is
  actually available;
- repair only high-confidence technical drift;
- produce evidence reports;
- stop with `GO`, `CONDITIONAL GO`, or `HOLD`.

## Files

- `TOTAL_AAA_MISSION_TASK.md` is the full Codex mission prompt.
- `TOTAL_AAA_MISSION_TASK_30_PLUS.md` is the stricter ZIP-installed 30-plus
  pass mission prompt used by `run-total-aaa-mission-30-plus.ps1`.
- `EXECUTIVE_SUMMARY.md` and the other audit report files are created by the
  mission when it runs.

## Local Launcher

From the repository root:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\run-total-aaa-mission.ps1
```

That prints repository status, validates the mission file path, and detects
local Roblox Studio installations.

To launch the long-running Codex mission:

```powershell
.\run-total-aaa-mission.ps1 -LaunchCodex
```

Equivalent 30-plus launcher:

```powershell
.\run-total-aaa-mission-30-plus.ps1 -LaunchCodex
```

The launcher refuses to run Codex if the working tree is dirty.

## Certification Boundary

This audit cannot promote any phase to Production Certified unless authoritative
runtime evidence actually exists and the repository certification authority
validates it. Studio detection, static validation, and generated reports are not
runtime evidence by themselves.

## Runtime Length

No prompt or launcher can guarantee an exact 30-minute runtime. This package
instead requires enough specific review work that a truthful completion should be
substantive: every file, every phase, every major module surface, every
documented invariant, and every reachable validation path must be covered before
the mission can end.
