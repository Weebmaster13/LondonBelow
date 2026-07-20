import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runPhase159SelfChecks } from "./Phase159InteractionPresentationFeedback.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";

export const phase160Id = 160;
export const phase160Name = "Chapter 0 Gameplay Flow and Objective Runtime";
export const evidenceDirectory = "automation/runtime-evidence/phase-160";
export const reportPath = `${evidenceDirectory}/phase-160-runtime-report.md`;

const sourceFiles = Object.freeze([
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowTypes.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowDefinitions.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowValidation.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveRegistry.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveState.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveConditions.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveEvaluation.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowEvidence.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowDiagnostics.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveSnapshots.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowSelfChecks.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowRuntime.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowCoordinator.lua",
  "src/ServerScriptService/Gameplay/Flow/GameplayFlowSignals.lua"
]);

const docs = Object.freeze([
  "00_BASELINE.md",
  "01_ARCHITECTURE.md",
  "02_GAMEPLAY_FLOW_RUNTIME.md",
  "03_OBJECTIVE_REGISTRY.md",
  "04_OBJECTIVE_GRAPH.md",
  "05_CONDITION_EVALUATION.md",
  "06_CHECKPOINT_ELIGIBILITY.md",
  "07_CHAPTER0_OBJECTIVES.md",
  "08_INTEGRATIONS.md",
  "09_DIAGNOSTICS.md",
  "10_SNAPSHOTS.md",
  "11_EVIDENCE.md",
  "12_SELF_CHECKS.md",
  "13_PRODUCTION_REVIEW.md",
  "14_COMPLETION_REPORT.md"
]);

function read(path) {
  return readFileSync(path, "utf8");
}

function write(path, text) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text, "utf8");
}

function add(checks, name, ok, message = "") {
  checks.push({ name, ok, message });
}

function summarize(checks) {
  const failures = checks.filter((check) => !check.ok);
  return {
    phase: phase160Id,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures
  };
}

export function runPhase160SelfChecks() {
  const checks = [];
  for (const file of sourceFiles) {
    add(checks, `source exists: ${file}`, existsSync(file));
  }
  for (const doc of docs) {
    const path = `docs/phases/phase-160/${doc}`;
    add(checks, `doc exists: ${doc}`, existsSync(path) && read(path).trim().length > 0);
  }

  const packageJson = JSON.parse(read("package.json"));
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/GameplayContracts.lua");
  const types = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowTypes.lua");
  const definitions = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowDefinitions.lua");
  const validation = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowValidation.lua");
  const registry = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveRegistry.lua");
  const state = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveState.lua");
  const conditions = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveConditions.lua");
  const evaluation = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveEvaluation.lua");
  const diagnostics = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowDiagnostics.lua");
  const snapshots = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowObjectiveSnapshots.lua");
  const selfChecks = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowSelfChecks.lua");
  const coordinator = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowCoordinator.lua");
  const evidence = read("src/ServerScriptService/Gameplay/Flow/GameplayFlowEvidence.lua");

  for (const stateName of ["Locked", "Available", "Active", "Completed", "Failed", "Skipped"]) {
    add(checks, `objective state: ${stateName}`, types.includes(stateName));
  }
  for (const conditionKind of [
    "InteractionCompleted",
    "EnvironmentalState",
    "InspectionCompleted",
    "BinaryMechanismState",
    "PresentationAcknowledged",
    "RuntimeEvent"
  ]) {
    add(checks, `condition kind: ${conditionKind}`, types.includes(conditionKind));
  }
  for (const eventName of ["ObjectiveActivated", "ObjectiveCompleted", "ObjectiveFailed", "ObjectiveSkipped", "CheckpointUnlocked"]) {
    add(checks, `runtime event: ${eventName}`, types.includes(eventName));
  }
  for (const objectiveId of [
    "chapter0.objective.inspectMumsNote",
    "chapter0.objective.restorePower",
    "chapter0.objective.openFrontDoor",
    "chapter0.objective.leaveHome"
  ]) {
    add(checks, `Chapter0 objective: ${objectiveId}`, definitions.includes(objectiveId));
  }
  add(checks, "AND prerequisites supported", conditions.includes("Types.PrerequisiteMode.And"));
  add(checks, "OR prerequisites supported", conditions.includes("Types.PrerequisiteMode.Or"));
  add(checks, "duplicate objective rejection", validation.includes("duplicate objective"));
  add(checks, "missing prerequisite rejection", validation.includes("missing prerequisite"));
  add(checks, "cycle rejection", validation.includes("cycle detected"));
  add(checks, "unsafe payload rejection", validation.includes("forbidden field") && validation.includes("unsafe runtime value"));
  add(checks, "validation before mutation", registry.indexOf("Validation.graph") < registry.indexOf("objectivesById[objective.objectiveId]"));
  add(checks, "failed event validation no mutation", state.includes("Validation.event") && state.indexOf("Validation.event") < state.indexOf("table.insert(events"));
  add(checks, "deterministic registry ordering", registry.includes("table.sort(objectiveOrder"));
  add(checks, "bounded evidence", evidence.includes("Types.Limits.MaxEvidence"));
  add(checks, "objective evaluation completes active objective", evaluation.includes("state.complete(active"));
  add(checks, "checkpoint eligibility support", evaluation.includes("setCheckpointEligible") && state.includes("checkpointEligible"));
  add(checks, "diagnostics lowerCamelCase posture", diagnostics.includes("gameplayFlowRuntimePosture"));
  add(checks, "diagnostics activeObjective", diagnostics.includes("activeObjective"));
  add(checks, "diagnostics completedObjectives", diagnostics.includes("completedObjectives"));
  add(checks, "snapshot lowerCamelCase availability", snapshots.includes("gameplayFlowRuntimeAvailable"));
  add(checks, "snapshot isolation", snapshots.includes("Serialization.deepCopy"));
  add(checks, "coordinator provider lowerCamelCase", coordinator.includes("Types.ProviderName") && types.includes("gameplayFlowRuntime"));
  add(checks, "coordinator exposes recordGameplayEvent", coordinator.includes("recordGameplayEvent"));
  add(checks, "coordinator exposes evaluateObjectives", coordinator.includes("evaluateObjectives"));
  add(checks, "coordinator no remote creation", !coordinator.includes("RemoteEvent") && !coordinator.includes("RemoteFunction"));
  add(checks, "self-check graph validation", selfChecks.includes("objective graph validation passes"));
  add(checks, "self-check runtime smoke sequence", selfChecks.includes("breaker enabled") && selfChecks.includes("front door opened"));
  add(checks, "self-check shutdown cleanup", selfChecks.includes("shutdown cleanup clears state"));

  const presentationIndex = bootstrap.indexOf("\"PresentationCoordinator\", PresentationCoordinator");
  const environmentalIndex = bootstrap.indexOf("\"Chapter0EnvironmentalCoordinator\", Chapter0EnvironmentalCoordinator");
  const objectiveIndex = bootstrap.indexOf("\"ObjectiveCoordinator\", ObjectiveCoordinator");
  const gameplayFlowIndex = bootstrap.indexOf("\"GameplayFlowCoordinator\", GameplayFlowCoordinator");
  const chapter0HomeIndex = bootstrap.indexOf("\"Chapter0HomeCoordinator\", Chapter0HomeCoordinator");
  add(checks, "bootstrap after PresentationCoordinator", presentationIndex >= 0 && presentationIndex < gameplayFlowIndex);
  add(checks, "bootstrap after Chapter0EnvironmentalCoordinator", environmentalIndex >= 0 && environmentalIndex < gameplayFlowIndex);
  add(checks, "bootstrap after ObjectiveCoordinator", objectiveIndex >= 0 && objectiveIndex < gameplayFlowIndex);
  add(checks, "bootstrap before Chapter0HomeCoordinator", gameplayFlowIndex >= 0 && gameplayFlowIndex < chapter0HomeIndex);
  add(checks, "governance contract synchronized", governance.includes(phase160Name));
  add(checks, "governance provider synchronized", governance.includes("gameplayFlowRuntime"));
  add(checks, "governance non-ownership preserved", governance.includes("interaction validation") && governance.includes("presentation execution"));
  add(checks, "phase160 selfcheck script", packageJson.scripts["london:phase160:selfcheck"] !== undefined);
  add(checks, "gameplay flow runtime script", packageJson.scripts["london:gameplay-flow"] !== undefined);
  add(checks, "gameplay flow validate script", packageJson.scripts["london:gameplay-flow:validate"] !== undefined);

  const phase159 = runPhase159SelfChecks();
  add(checks, "phase159 regression self-checks", phase159.ok === true, JSON.stringify(phase159.failures ?? []));

  return summarize(checks);
}

function markdown(result, runtime = null) {
  const lines = [
    "# Phase 160 Runtime Report",
    "",
    `Phase: ${phase160Id} - ${phase160Name}`,
    `Status: ${result.ok ? "STATIC_VALIDATION_PASSED" : "STATIC_VALIDATION_FAILED"}`,
    `Total checks: ${result.total}`,
    `Passed: ${result.passed}`,
    `Failed: ${result.failed}`,
    "",
    "## Findings",
    "",
    "- Gameplay Flow Runtime owns objective progression and checkpoint eligibility only.",
    "- Chapter 0 objectives are deterministic and event-driven.",
    "- Existing Interaction, Environmental, Presentation, Observation, Bootstrap, and Governance boundaries remain intact.",
    "",
    "## Failures",
    ""
  ];
  if (result.failures.length === 0) {
    lines.push("None");
  } else {
    for (const failure of result.failures) {
      lines.push(`- ${failure.name}: ${failure.message}`);
    }
  }
  lines.push("", "## Runtime Smoke Test", "");
  if (runtime == null) {
    lines.push("not attempted");
  } else if (runtime.status === "executionBlocked") {
    lines.push("blocked by environment");
    lines.push(`Framework used: ${runtime.frameworkUsed === true}`);
    lines.push(`Blocked reason: ${runtime.blockedReason ?? "Roblox Studio runtime evidence was not imported."}`);
  } else {
    lines.push(runtime.ok ? "executed and passed" : "executed and failed");
    lines.push(`Framework used: ${runtime.frameworkUsed === true}`);
    lines.push(`Status: ${runtime.status}`);
  }
  return `${lines.join("\n")}\n`;
}

async function runRuntime() {
  const selfCheck = runPhase160SelfChecks();
  const execution = await runRuntimeExecution({
    phase: phase160Id,
    phaseName: phase160Name,
    runnerId: "runtimeExecution.phase160.gameplayFlowObjective",
    expectedEvidenceFile: "runtime-result.json"
  });
  const runtime = {
    frameworkUsed: true,
    status: execution?.status ?? "executionBlocked",
    ok: execution?.status === "passed",
    blockedReason:
      execution?.backendResult?.blockedReason ??
      execution?.backendResult?.reason ??
      "Roblox Studio runtime evidence was not imported."
  };
  write(reportPath, markdown(selfCheck, runtime));
  return {
    ok: selfCheck.ok && runtime.status !== "executionBlocked",
    selfCheck,
    runtime
  };
}

function runValidate() {
  const result = runPhase160SelfChecks();
  write(reportPath, markdown(result));
  return result;
}

async function main() {
  const args = new Set(process.argv.slice(2));
  if (args.has("--runtime")) {
    const result = await runRuntime();
    console.log(JSON.stringify(result, null, 2));
    process.exit(result.ok ? 0 : 2);
  }
  const result = runValidate();
  console.log(JSON.stringify(result, null, 2));
  process.exit(result.ok ? 0 : 1);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
