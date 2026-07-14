import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

function readMaybe(path) {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return "";
  }
}

export function createRunId(date = new Date()) {
  const pad = (value) => String(value).padStart(2, "0");
  return `${date.getFullYear()}${pad(date.getMonth() + 1)}${pad(date.getDate())}-${pad(
    date.getHours()
  )}${pad(date.getMinutes())}${pad(date.getSeconds())}`;
}

export function determineNextPhase(state) {
  if (!state?.nextRecommendedPhase || !state?.nextRecommendedPhaseName) {
    throw new Error("Unable to determine next phase from automation state.");
  }
  return {
    phase: state.nextRecommendedPhase,
    name: state.nextRecommendedPhaseName,
    baselinePhase: state.lastCertifiedPhase,
    baselineName: state.lastCertifiedPhaseName,
    baselineCommit: state.lastCertifiedCommit,
    maturity: state.nextRecommendedPhaseName.includes("Production Hardening")
      ? "Hardening"
      : "Foundation"
  };
}

export function generateSpecification({ phase, repo, runId, runRoot }) {
  mkdirSync(runRoot, { recursive: true });
  const roadmap = readMaybe("ROADMAP.md");
  const tasks = readMaybe("TASKS.md");
  const master = readMaybe("LONDON_ENGINE_MASTER_CONTEXT.md");
  const content = `# Phase ${phase.phase} Specification - ${phase.name}

Run ID: ${runId}

## Certified Baseline

- Certified phase: Phase ${phase.baselinePhase} - ${phase.baselineName}
- Certified commit: ${phase.baselineCommit}
- Local HEAD: ${repo.localHead}
- Remote HEAD: ${repo.remoteHead}
- Branch: ${repo.branch}

## Architectural Purpose

Determine and implement exactly one next London Engine phase from the repository source of truth. The work must preserve certified runtime boundaries, avoid fake complexity, avoid hidden authority, and complete only the active phase.

## Scope Discipline

- Implement Phase ${phase.phase} only.
- Do not begin Phase ${phase.phase + 1}.
- Do not add live behavior unless explicitly approved by a major architecture gate.
- Do not fabricate validation, commits, links, or certification evidence.

## Code-First Inspection Targets

- AGENTS.md
- ENGINE_CONSTITUTION.md
- LONDON_ENGINE.md
- LONDON_ENGINE_MASTER_CONTEXT.md
- ROADMAP.md
- TASKS.md
- src/ServerScriptService/Core/Bootstrap.server.lua
- src/ServerScriptService/Core/Governance/EngineContractRegistry.lua
- current subsystem Types, Validation, State, Serialization, Diagnostics, Snapshots, Signals, SelfChecks, Coordinator, wrapper runtimes, and docs

## Current Repository Signals

ROADMAP current milestone excerpt:

\`\`\`text
${roadmap.match(/The current certified milestone[^\n]*/)?.[0] ?? "Not found"}
\`\`\`

TASKS current milestone excerpt:

\`\`\`text
${tasks.match(/Phase \d+:[^\n]*current certified technical milestone[^\n]*/)?.[0] ?? "Not found"}
\`\`\`

Master context current milestone excerpt:

\`\`\`text
${master.match(/Current certified milestone:[^\n]*/)?.[0] ?? "Not found"}
\`\`\`

## Required Validation

- stylua src
- stylua --check src
- selene src
- rojo sourcemap default.project.json --output sourcemap.json
- rojo build default.project.json --output rojo-verify.rbxlx
- git diff --check
- phase-specific self-checks
- upstream regression self-checks where available
- forbidden API and runtime-surface scans
- exact-commit validation
- push and remote verification

## Commit Message

Use a focused Phase ${phase.phase} commit message derived from the implemented scope. Do not combine phases.
`;
  const specPath = join(runRoot, `phase-${phase.phase}-specification.md`);
  writeFileSync(specPath, content);
  return specPath;
}

export function generateArchitectureReview({ phase, runRoot }) {
  const content = `# Phase ${phase.phase} Architecture Review - ${phase.name}

## Architecture Value Test

The phase may proceed only if it provides capability, safety, maintainability, integration, or production value. If code-first inspection shows the work is redundant, the phase must be redesigned or stopped.

## Runtime Necessity Test

Do not create a new runtime, provider, coordinator, snapshot provider, Bootstrap entry, or Governance contract unless the repository proves distinct ownership and lifecycle are required.

## Major Gate Check

Stop for human approval before introducing live workflow execution, Registry mutation, adapter registration, adapter activation, adapter execution, routing, dispatch, queues, scheduling, orchestration, asset loading, presentation, gameplay, persistence writes, networking, or Chapter behavior.

## Critic Result

No implementation is approved by this file alone. The implementation agent must inspect the current repository, revise the plan if evidence contradicts this specification, and report any blocker truthfully.
`;
  const reviewPath = join(runRoot, `phase-${phase.phase}-architecture-review.md`);
  writeFileSync(reviewPath, content);
  return reviewPath;
}
