import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runPhase156SelfChecks } from "./Phase156InteractionRuntimeFoundation.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";

export const phase157Id = 157;
export const phase157Name = "Environmental Interaction Content Foundation";
export const evidenceDirectory = "automation/runtime-evidence/phase-157";
export const reportPath = `${evidenceDirectory}/phase-157-runtime-report.md`;

const sourceFiles = Object.freeze([
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalInteractionCoordinator.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalObjectRegistry.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalDefinitionValidation.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalStateRuntime.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalTransitionRuntime.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalFamilyRegistry.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalPresentationAdapter.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalDiagnostics.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalSnapshots.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalSelfChecks.lua",
  "src/ServerScriptService/Interaction/Environmental/Families/BinaryMechanismFamily.lua",
  "src/ServerScriptService/Interaction/Environmental/Families/InspectableObjectFamily.lua",
  "src/ServerScriptService/Interaction/Environmental/Families/MomentaryActuatorFamily.lua"
]);

const docs = Object.freeze([
  "PHASE_157_OVERVIEW.md",
  "PHASE_157_BASELINE.md",
  "PHASE_157_ARCHITECTURE.md",
  "PHASE_157_SCOPE.md",
  "PHASE_157_ENVIRONMENTAL_MODEL.md",
  "PHASE_157_OBJECT_IDENTITY.md",
  "PHASE_157_DEFINITION_CONTRACT.md",
  "PHASE_157_FAMILY_MODEL.md",
  "PHASE_157_BINARY_MECHANISMS.md",
  "PHASE_157_INSPECTABLE_OBJECTS.md",
  "PHASE_157_MOMENTARY_ACTUATORS.md",
  "PHASE_157_REGISTRATION_LIFECYCLE.md",
  "PHASE_157_STATE_MODEL.md",
  "PHASE_157_TRANSITION_ENGINE.md",
  "PHASE_157_INTERACTION_RUNTIME_INTEGRATION.md",
  "PHASE_157_OBSERVATION_INTEGRATION.md",
  "PHASE_157_DEPENDENCY_BINDING.md",
  "PHASE_157_RESET_POLICY.md",
  "PHASE_157_PRESENTATION_STATE.md",
  "PHASE_157_DIAGNOSTICS.md",
  "PHASE_157_RUNTIME_EVIDENCE.md",
  "PHASE_157_SECURITY_REVIEW.md",
  "PHASE_157_FAILURE_INJECTION.md",
  "PHASE_157_PERFORMANCE_REVIEW.md",
  "PHASE_157_SELF_CHECKS.md",
  "PHASE_157_RUNTIME_SMOKE_TEST.md",
  "PHASE_157_VALIDATION.md",
  "PHASE_157_COMPLETION_REPORT.md"
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
    phase: phase157Id,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures
  };
}

export function runPhase157SelfChecks() {
  const checks = [];
  for (const file of sourceFiles) {
    add(checks, `source exists: ${file}`, existsSync(file));
  }
  for (const doc of docs) {
    const path = `docs/phases/phase-157/${doc}`;
    add(checks, `doc exists: ${doc}`, existsSync(path) && read(path).trim().length > 0);
  }

  const packageJson = JSON.parse(read("package.json"));
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const coordinator = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalInteractionCoordinator.lua");
  const registry = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalObjectRegistry.lua");
  const transition = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalTransitionRuntime.lua");
  const diagnostics = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalDiagnostics.lua");
  const selfChecks = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalSelfChecks.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/GameplayContracts.lua");

  add(checks, "bootstrap registered after interaction", bootstrap.indexOf("InteractionCoordinator") < bootstrap.indexOf("EnvironmentalInteractionCoordinator"));
  add(checks, "uses Phase 156 registerTarget", registry.includes("InteractionCoordinator.registerTarget"));
  add(checks, "uses Phase 156 registerInteraction", registry.includes("InteractionCoordinator.registerInteraction"));
  add(checks, "uses Phase 156 requestInteraction", registry.includes("InteractionCoordinator.requestInteraction"));
  add(checks, "rollback unregisters target", registry.includes("unregisterTarget"));
  add(checks, "rollback unregisters interactions", registry.includes("unregisterInteraction"));
  add(checks, "transition evaluate is plan-first", transition.includes("function TransitionRuntime.evaluate"));
  add(checks, "binary family covered", selfChecks.includes("validBinaryOpen"));
  add(checks, "inspectable family covered", selfChecks.includes("validInspection"));
  add(checks, "actuator family covered", selfChecks.includes("validActuatorActivation"));
  add(checks, "repeat inspection rejection covered", selfChecks.includes("repeatInspectionRejects"));
  add(checks, "unsupported action rejection covered", selfChecks.includes("unsupportedActionRejects"));
  add(checks, "diagnostics posture lowerCamelCase", diagnostics.includes("environmentalInteractionRuntimePosture"));
  add(checks, "no new remotes posture", diagnostics.includes("noNewRemotes"));
  add(checks, "public coordinator registerDefinition", coordinator.includes("function Coordinator.registerDefinition"));
  add(checks, "public coordinator requestAction", coordinator.includes("function Coordinator.requestAction"));
  add(checks, "public coordinator unregisterObject", coordinator.includes("function Coordinator.unregisterObject"));
  add(checks, "governance contract synchronized", governance.includes("Environmental Interaction Content Foundation"));
  add(checks, "phase157 selfcheck script", packageJson.scripts["london:phase157:selfcheck"] !== undefined);
  add(checks, "environmental runtime script", packageJson.scripts["london:environmental-interactions"] !== undefined);
  add(checks, "environmental validate script", packageJson.scripts["london:environmental-interactions:validate"] !== undefined);

  const phase156 = runPhase156SelfChecks();
  add(checks, "phase156 regression self-checks", phase156.ok === true, JSON.stringify(phase156.failures ?? []));

  return summarize(checks);
}

function markdown(result, runtime = null) {
  const lines = [
    "# Phase 157 Runtime Report",
    "",
    `Phase: ${phase157Id} - ${phase157Name}`,
    `Status: ${result.ok ? "STATIC_VALIDATION_PASSED" : "STATIC_VALIDATION_FAILED"}`,
    `Total checks: ${result.total}`,
    `Passed: ${result.passed}`,
    `Failed: ${result.failed}`,
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
    lines.push("Not executed by this command.");
  } else {
    lines.push(`Framework used: ${runtime.frameworkUsed === true}`);
    lines.push(`Status: ${runtime.status}`);
    lines.push(`Blocked reason: ${runtime.blockedReason ?? "None"}`);
  }
  return `${lines.join("\n")}\n`;
}

async function runRuntime() {
  const selfCheck = runPhase157SelfChecks();
  const execution = await runRuntimeExecution({
    phase: phase157Id,
    phaseName: phase157Name,
    runnerId: "runtimeExecution.phase157.environmentalInteractions",
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
  const result = runPhase157SelfChecks();
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
