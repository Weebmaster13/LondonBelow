import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runPhase156SelfChecks } from "./Phase156InteractionRuntimeFoundation.mjs";
import { runPhase157SelfChecks } from "./Phase157EnvironmentalInteractionContent.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";

export const phase158Id = 158;
export const phase158Name = "Environmental Interaction Runtime Hardening and Chapter 0 Binding";
export const evidenceDirectory = "automation/runtime-evidence/phase-158";
export const reportPath = `${evidenceDirectory}/phase-158-runtime-report.md`;

const sourceFiles = Object.freeze([
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalTypes.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalStateRuntime.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalObjectRegistry.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalInteractionCoordinator.lua",
  "src/ServerScriptService/Interaction/Environmental/EnvironmentalSelfChecks.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalCoordinator.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalTypes.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureCatalog.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureValidation.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureBinder.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureRegistry.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalState.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalDiagnostics.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalSnapshots.lua",
  "src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalSelfChecks.lua"
]);

const docs = Object.freeze([
  "00_BASELINE.md",
  "01_ARCHITECTURE.md",
  "02_RUNTIME_HARDENING.md",
  "03_CHAPTER0_BINDING.md",
  "04_FIXTURE_CATALOG.md",
  "05_AUTHORED_INSTANCE_BINDING.md",
  "06_BATCH_REGISTRATION.md",
  "07_ROLLBACK.md",
  "08_READINESS_POSTURE.md",
  "09_STATE_REVISIONS.md",
  "10_DEPENDENCY_BINDING.md",
  "11_PRESENTATION_BINDING.md",
  "12_RESET_ORCHESTRATION.md",
  "13_RECONCILIATION.md",
  "14_SELF_CHECKS.md",
  "15_VALIDATION.md",
  "16_PRODUCTION_REVIEW.md",
  "17_COMPLETION_REPORT.md"
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
    phase: phase158Id,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures
  };
}

export function runPhase158SelfChecks() {
  const checks = [];
  for (const file of sourceFiles) {
    add(checks, `source exists: ${file}`, existsSync(file));
  }
  for (const doc of docs) {
    const path = `docs/phases/phase-158/${doc}`;
    add(checks, `doc exists: ${doc}`, existsSync(path) && read(path).trim().length > 0);
  }

  const packageJson = JSON.parse(read("package.json"));
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/GameplayContracts.lua");
  const catalog = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureCatalog.lua");
  const types = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalTypes.lua");
  const coordinator = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalCoordinator.lua");
  const registry = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureRegistry.lua");
  const binder = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0FixtureBinder.lua");
  const diagnostics = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalDiagnostics.lua");
  const snapshots = read("src/ServerScriptService/Chapter0Home/Environment/Chapter0EnvironmentalSnapshots.lua");
  const envState = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalStateRuntime.lua");
  const envRegistry = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalObjectRegistry.lua");
  const envSelfChecks = read("src/ServerScriptService/Interaction/Environmental/EnvironmentalSelfChecks.lua");

  add(checks, "fixture catalog has eight fixture entries", (catalog.match(/chapter0\.home\./g) ?? []).length >= 8);
  add(checks, "fixture catalog includes BinaryMechanism", catalog.includes("BinaryMechanism"));
  add(checks, "fixture catalog includes InspectableObject", catalog.includes("InspectableObject"));
  add(checks, "fixture catalog includes MomentaryActuator", catalog.includes("MomentaryActuator"));
  add(checks, "authored instance required flags present", catalog.includes("authoredInstanceRequired"));
  add(checks, "binder rejects missing required", binder.includes("required authored instance is unavailable"));
  add(checks, "Chapter0 batch registration uses Environmental runtime", registry.includes("EnvironmentalInteractionCoordinator.registerDefinitions"));
  add(checks, "Chapter0 rollback reset unregisters fixtures", registry.includes("EnvironmentalInteractionCoordinator.unregisterObject"));
  add(checks, "Chapter0 reconciliation uses Environmental runtime", registry.includes("EnvironmentalInteractionCoordinator.reconcile"));
  const environmentalRegister = bootstrap.indexOf("\"EnvironmentalInteractionCoordinator\",\n\t\tEnvironmentalInteractionCoordinator");
  const chapter0Register = bootstrap.indexOf("\"Chapter0EnvironmentalCoordinator\", Chapter0EnvironmentalCoordinator");
  const chapter0HomeRegister = bootstrap.indexOf("\"Chapter0HomeCoordinator\", Chapter0HomeCoordinator");
  add(checks, "provider name lowerCamelCase", coordinator.includes("Types.ProviderName") && types.includes("chapter0EnvironmentalRuntime"));
  add(checks, "diagnostics posture lowerCamelCase", diagnostics.includes("chapter0EnvironmentalBindingPosture"));
  add(checks, "snapshots posture lowerCamelCase", snapshots.includes("chapter0EnvironmentalBindingPosture"));
  add(checks, "bootstrap after EnvironmentalInteractionCoordinator", environmentalRegister >= 0 && environmentalRegister < chapter0Register);
  add(checks, "bootstrap before Chapter0HomeCoordinator registration", chapter0Register >= 0 && chapter0Register < chapter0HomeRegister);
  add(checks, "governance contract synchronized", governance.includes(phase158Name));
  add(checks, "governance provider synchronized", governance.includes("chapter0EnvironmentalRuntime"));
  add(checks, "state revision compare-and-commit", envState.includes("commitWithRevision") && envState.includes("StateRevisionMismatch"));
  add(checks, "idempotent request completion", envState.includes("completedRequests") && envRegistry.includes("getCompletedRequest"));
  add(checks, "batch rollback hardening", envRegistry.includes("registerBatch") && envRegistry.includes("BatchRegistrationFailed"));
  add(checks, "environmental reconciliation hardening", envRegistry.includes("function Registry.reconcile"));
  add(checks, "Phase157 self-checks expanded", envSelfChecks.includes("duplicateCompletionIdempotent") && envSelfChecks.includes("staleRevisionRejects"));
  add(checks, "phase158 selfcheck script", packageJson.scripts["london:phase158:selfcheck"] !== undefined);
  add(checks, "chapter0 environmental runtime script", packageJson.scripts["london:chapter0-environment"] !== undefined);
  add(checks, "chapter0 environmental validate script", packageJson.scripts["london:chapter0-environment:validate"] !== undefined);

  const phase156 = runPhase156SelfChecks();
  add(checks, "phase156 regression self-checks", phase156.ok === true, JSON.stringify(phase156.failures ?? []));
  const phase157 = runPhase157SelfChecks();
  add(checks, "phase157 regression self-checks", phase157.ok === true, JSON.stringify(phase157.failures ?? []));

  return summarize(checks);
}

function markdown(result, runtime = null) {
  const lines = [
    "# Phase 158 Runtime Report",
    "",
    `Phase: ${phase158Id} - ${phase158Name}`,
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
  const selfCheck = runPhase158SelfChecks();
  const execution = await runRuntimeExecution({
    phase: phase158Id,
    phaseName: phase158Name,
    runnerId: "runtimeExecution.phase158.chapter0EnvironmentalBinding",
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
  const result = runPhase158SelfChecks();
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
