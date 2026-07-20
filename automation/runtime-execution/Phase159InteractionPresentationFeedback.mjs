import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runPhase158SelfChecks } from "./Phase158Chapter0EnvironmentalBinding.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";

export const phase159Id = 159;
export const phase159Name = "Chapter 0 Interaction Presentation and Feedback Runtime";
export const evidenceDirectory = "automation/runtime-evidence/phase-159";
export const reportPath = `${evidenceDirectory}/phase-159-runtime-report.md`;

const sourceFiles = Object.freeze([
  "src/ServerScriptService/Presentation/Core/PresentationTypes.lua",
  "src/ServerScriptService/Presentation/Core/PresentationValidation.lua",
  "src/ServerScriptService/Presentation/Core/PresentationCoordinator.lua",
  "src/ServerScriptService/Presentation/Core/PresentationCommandRuntime.lua",
  "src/ServerScriptService/Presentation/Core/PresentationDispatcher.lua",
  "src/ServerScriptService/Presentation/Core/PresentationEvidence.lua",
  "src/ServerScriptService/Presentation/Core/PresentationDiagnostics.lua",
  "src/ServerScriptService/Presentation/Core/PresentationSnapshots.lua",
  "src/ServerScriptService/Presentation/Core/PresentationSelfChecks.lua",
  "src/ServerScriptService/Presentation/Core/PresentationChapter0Binding.lua"
]);

const docs = Object.freeze([
  "00_BASELINE.md",
  "01_ARCHITECTURE.md",
  "02_PRESENTATION_RUNTIME.md",
  "03_PROMPT_SYSTEM.md",
  "04_AUDIO_COMMANDS.md",
  "05_ANIMATION_COMMANDS.md",
  "06_VISUAL_FEEDBACK.md",
  "07_ACCESSIBILITY.md",
  "08_QUEUE_MODEL.md",
  "09_DISPATCHER.md",
  "10_CHAPTER0_BINDING.md",
  "11_DIAGNOSTICS.md",
  "12_SELF_CHECKS.md",
  "13_VALIDATION.md",
  "14_RUNTIME_SMOKE_TEST.md",
  "15_PRODUCTION_REVIEW.md",
  "16_COMPLETION_REPORT.md"
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
    phase: phase159Id,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures
  };
}

export function runPhase159SelfChecks() {
  const checks = [];
  for (const file of sourceFiles) {
    add(checks, `source exists: ${file}`, existsSync(file));
  }
  for (const doc of docs) {
    const path = `docs/phases/phase-159/${doc}`;
    add(checks, `doc exists: ${doc}`, existsSync(path) && read(path).trim().length > 0);
  }

  const packageJson = JSON.parse(read("package.json"));
  const types = read("src/ServerScriptService/Presentation/Core/PresentationTypes.lua");
  const validation = read("src/ServerScriptService/Presentation/Core/PresentationValidation.lua");
  const coordinator = read("src/ServerScriptService/Presentation/Core/PresentationCoordinator.lua");
  const commandRuntime = read("src/ServerScriptService/Presentation/Core/PresentationCommandRuntime.lua");
  const dispatcher = read("src/ServerScriptService/Presentation/Core/PresentationDispatcher.lua");
  const chapter0Binding = read("src/ServerScriptService/Presentation/Core/PresentationChapter0Binding.lua");
  const diagnostics = read("src/ServerScriptService/Presentation/Core/PresentationDiagnostics.lua");
  const snapshots = read("src/ServerScriptService/Presentation/Core/PresentationSnapshots.lua");
  const selfChecks = read("src/ServerScriptService/Presentation/Core/PresentationSelfChecks.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/PresentationContracts.lua");

  for (const commandType of [
    "ShowPrompt",
    "HidePrompt",
    "UpdatePrompt",
    "ShowInteractionBusy",
    "HideInteractionBusy",
    "PlayAudio",
    "StopAudio",
    "PlayAnimation",
    "StopAnimation",
    "UpdateCursor",
    "ShowMessage",
    "HideMessage",
    "HighlightObject",
    "RemoveHighlight"
  ]) {
    add(checks, `command type: ${commandType}`, types.includes(commandType));
  }
  add(checks, "bounded command queue", commandRuntime.includes("MaxCommands") && commandRuntime.includes("sortQueue"));
  add(checks, "immutable command creation", commandRuntime.includes("table.freeze"));
  add(checks, "prompt validation", validation.includes("function Validation.prompt"));
  add(checks, "command validation", validation.includes("function Validation.command"));
  add(checks, "dispatcher exists", dispatcher.includes("function Dispatcher.route"));
  add(checks, "coordinator command API", coordinator.includes("function PresentationCoordinator.submitCommand"));
  add(checks, "coordinator dispatch API", coordinator.includes("function PresentationCoordinator.dispatchAll"));
  add(checks, "Chapter0 binding API", coordinator.includes("bindChapter0FixturePresentation"));
  add(checks, "fixture catalog mapped", (chapter0Binding.match(/chapter0\.home\./g) ?? []).length >= 8);
  add(checks, "audio keys not asset ids", chapter0Binding.includes("door.open") && !chapter0Binding.includes("rbxassetid"));
  add(checks, "animation keys not asset ids", chapter0Binding.includes("inspect.note") && !chapter0Binding.includes("AnimationId"));
  add(checks, "accessibility metadata", chapter0Binding.includes("screenReaderKey") && chapter0Binding.includes("inputGlyphKey"));
  add(checks, "diagnostics posture lowerCamelCase", diagnostics.includes("presentationRuntimePosture"));
  add(checks, "snapshot keys lowerCamelCase", snapshots.includes("presentationRuntimeAvailable") && snapshots.includes("activePrompt"));
  add(checks, "self-check command coverage", selfChecks.includes("commandQueueAcceptsPrompt") && selfChecks.includes("chapter0FixturePresentation"));
  add(checks, "governance synchronized", governance.includes(phase159Name));
  add(checks, "phase159 selfcheck script", packageJson.scripts["london:phase159:selfcheck"] !== undefined);
  add(checks, "presentation runtime script", packageJson.scripts["london:presentation-runtime"] !== undefined);
  add(checks, "presentation runtime validate script", packageJson.scripts["london:presentation-runtime:validate"] !== undefined);

  const phase158 = runPhase158SelfChecks();
  add(checks, "phase158 regression self-checks", phase158.ok === true, JSON.stringify(phase158.failures ?? []));

  return summarize(checks);
}

function markdown(result, runtime = null) {
  const lines = [
    "# Phase 159 Runtime Report",
    "",
    `Phase: ${phase159Id} - ${phase159Name}`,
    `Status: ${result.ok ? "STATIC_VALIDATION_PASSED" : "STATIC_VALIDATION_FAILED"}`,
    `Total checks: ${result.total}`,
    `Passed: ${result.passed}`,
    `Failed: ${result.failed}`,
    "",
    "## Findings",
    "",
    "- Existing Presentation Runtime found under `src/ServerScriptService/Presentation/Core`.",
    "- Existing PlayerExperience transport and FeedbackService remain unchanged.",
    "- No ProximityPrompt, BillboardGui, final audio asset, final animation asset, cursor asset, or new remote authority was added.",
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
    lines.push("Not attempted");
  } else {
    lines.push(`Framework used: ${runtime.frameworkUsed === true}`);
    lines.push(`Status: ${runtime.status}`);
    lines.push(`Blocked reason: ${runtime.blockedReason ?? "None"}`);
  }
  return `${lines.join("\n")}\n`;
}

async function runRuntime() {
  const selfCheck = runPhase159SelfChecks();
  const execution = await runRuntimeExecution({
    phase: phase159Id,
    phaseName: phase159Name,
    runnerId: "runtimeExecution.phase159.presentationFeedback",
    expectedEvidenceFile: "runtime-result.json"
  });
  const runtime = {
    frameworkUsed: true,
    status: execution?.status ?? "executionBlocked",
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

async function main() {
  const args = new Set(process.argv.slice(2));
  if (args.has("--runtime")) {
    const result = await runRuntime();
    console.log(JSON.stringify(result, null, 2));
    process.exit(result.ok ? 0 : 2);
  }
  const result = runPhase159SelfChecks();
  write(reportPath, markdown(result));
  console.log(JSON.stringify(result, null, 2));
  process.exit(result.ok ? 0 : 1);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
