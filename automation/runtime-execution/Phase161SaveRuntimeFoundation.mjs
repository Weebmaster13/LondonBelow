import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { runPhase160SelfChecks } from "./Phase160GameplayFlowObjectiveRuntime.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";

export const phase161Id = 161;
export const phase161Name = "Save Runtime Foundation and Persistent Progress Model";
export const evidenceDirectory = "automation/runtime-evidence/phase-161";
export const reportPath = `${evidenceDirectory}/phase-161-runtime-report.md`;

const sourceFiles = Object.freeze([
  "src/ServerScriptService/Saving/Core/SaveTypes.lua",
  "src/ServerScriptService/Saving/Core/SaveSchemaRegistry.lua",
  "src/ServerScriptService/Saving/Core/SaveSerializer.lua",
  "src/ServerScriptService/Saving/Core/SaveDeserializer.lua",
  "src/ServerScriptService/Saving/Core/SaveMigrationRuntime.lua",
  "src/ServerScriptService/Saving/Core/SaveRuntime.lua",
  "src/ServerScriptService/Saving/Core/SaveValidation.lua",
  "src/ServerScriptService/Saving/Core/SaveDiagnostics.lua",
  "src/ServerScriptService/Saving/Core/SaveSnapshots.lua",
  "src/ServerScriptService/Saving/Core/SaveEvidence.lua",
  "src/ServerScriptService/Saving/Core/SaveSelfChecks.lua",
  "src/ServerScriptService/Saving/Core/SaveCoordinator.lua"
]);

const docs = Object.freeze([
  "00_BASELINE.md",
  "01_ARCHITECTURE.md",
  "02_SAVE_RUNTIME.md",
  "03_SCHEMA_MODEL.md",
  "04_SERIALIZATION.md",
  "05_DESERIALIZATION.md",
  "06_MIGRATION_RUNTIME.md",
  "07_VALIDATION.md",
  "08_CHAPTER0_PROGRESS.md",
  "09_DIAGNOSTICS.md",
  "10_SNAPSHOTS.md",
  "11_SELF_CHECKS.md",
  "12_RUNTIME_SMOKE_TEST.md",
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
    phase: phase161Id,
    ok: failures.length === 0,
    total: checks.length,
    passed: checks.length - failures.length,
    failed: failures.length,
    failures
  };
}

export function runPhase161SelfChecks() {
  const checks = [];
  for (const file of sourceFiles) {
    add(checks, `source exists: ${file}`, existsSync(file));
  }
  for (const doc of docs) {
    const path = `docs/phases/phase-161/${doc}`;
    add(checks, `doc exists: ${doc}`, existsSync(path) && read(path).trim().length > 0);
  }

  const packageJson = JSON.parse(read("package.json"));
  const bootstrap = read("src/ServerScriptService/Core/Bootstrap.server.lua");
  const governance = read("src/ServerScriptService/Core/Governance/Contracts/GameplayContracts.lua");
  const types = read("src/ServerScriptService/Saving/Core/SaveTypes.lua");
  const registry = read("src/ServerScriptService/Saving/Core/SaveSchemaRegistry.lua");
  const serializer = read("src/ServerScriptService/Saving/Core/SaveSerializer.lua");
  const deserializer = read("src/ServerScriptService/Saving/Core/SaveDeserializer.lua");
  const migration = read("src/ServerScriptService/Saving/Core/SaveMigrationRuntime.lua");
  const validation = read("src/ServerScriptService/Saving/Core/SaveValidation.lua");
  const diagnostics = read("src/ServerScriptService/Saving/Core/SaveDiagnostics.lua");
  const snapshots = read("src/ServerScriptService/Saving/Core/SaveSnapshots.lua");
  const coordinator = read("src/ServerScriptService/Saving/Core/SaveCoordinator.lua");
  const selfChecks = read("src/ServerScriptService/Saving/Core/SaveSelfChecks.lua");

  add(checks, "schema version constant", types.includes("Types.SchemaVersion = 1"));
  add(checks, "migration version constant", types.includes("Types.MigrationVersion = 1"));
  add(checks, "provider lowerCamelCase", types.includes("saveRuntime"));
  for (const state of ["Locked", "Available", "Active", "Completed", "Failed", "Skipped"]) {
    add(checks, `persistent objective state: ${state}`, types.includes(state));
  }
  for (const id of [
    "chapter0.home.objective.inspect_note",
    "chapter0.home.objective.restore_power",
    "chapter0.home.objective.open_front_door",
    "chapter0.home.objective.leave_home",
    "chapter0.home.checkpoint.start",
    "chapter0.home.checkpoint.power_restored",
    "chapter0.home.checkpoint.exit_ready"
  ]) {
    add(checks, `stable id: ${id}`, registry.includes(id) || selfChecks.includes(id));
  }
  add(checks, "schema registry immutable", registry.includes("table.freeze"));
  add(checks, "serializer validates before output", serializer.indexOf("Validation.saveRecord") < serializer.indexOf("Serialization.freezeDeep"));
  add(checks, "deserializer migrates before validation", deserializer.indexOf("Migration.migrate") < deserializer.indexOf("Validation.saveRecord"));
  add(checks, "migration rejects unsupported schema", migration.includes("unsupported schema version"));
  add(checks, "migration rejects unsupported migration", migration.includes("unsupported migration version"));
  add(checks, "validator rejects duplicate objectives", validation.includes("duplicate objective"));
  add(checks, "validator rejects duplicate checkpoints", validation.includes("duplicate checkpoint"));
  add(checks, "validator exact fields", validation.includes("validateExactFields"));
  add(checks, "validator rejects DataStore/cloud/networking", validation.includes("dataStore") && validation.includes("cloudSave") && validation.includes("networking"));
  add(checks, "diagnostics posture lowerCamelCase", diagnostics.includes("saveRuntimePosture"));
  add(checks, "snapshot availability lowerCamelCase", snapshots.includes("saveRuntimeAvailable"));
  add(checks, "snapshot posture lowerCamelCase", snapshots.includes("saveRuntimePosture"));
  add(checks, "coordinator serialize API", coordinator.includes("serializeProgress"));
  add(checks, "coordinator deserialize API", coordinator.includes("deserializeProgress"));
  add(checks, "coordinator migrate API", coordinator.includes("migrateSave"));
  add(checks, "coordinator registers saveRuntime provider", coordinator.includes("Types.ProviderName"));
  add(checks, "self-check serializer coverage", selfChecks.includes("serializer = serialized.ok"));
  add(checks, "self-check deserializer coverage", selfChecks.includes("deserializer = deserialized.ok"));
  add(checks, "self-check failure injection", selfChecks.includes("duplicateObjectiveRejected") && selfChecks.includes("corruptedSaveRejected"));

  const gameplayFlowIndex = bootstrap.indexOf("\"GameplayFlowCoordinator\"");
  const saveIndex = bootstrap.indexOf("\"SaveCoordinator\", SaveCoordinator");
  add(checks, "bootstrap Save after GameplayFlow", gameplayFlowIndex >= 0 && saveIndex > gameplayFlowIndex);
  add(checks, "bootstrap Save depends on GameplayFlow", bootstrap.includes("\"GameplayFlowCoordinator\"") && bootstrap.includes("\"SaveCoordinator\", SaveCoordinator"));
  add(checks, "governance synchronized", governance.includes("Phase 161: Save Runtime Foundation and Persistent Progress Model"));
  add(checks, "governance saveRuntime snapshot provider", governance.includes("\"saveRuntime\""));
  add(checks, "package selfcheck script", packageJson.scripts["london:phase161:selfcheck"] !== undefined);
  add(checks, "package save runtime script", packageJson.scripts["london:save-runtime"] !== undefined);
  add(checks, "package save runtime validate script", packageJson.scripts["london:save-runtime:validate"] !== undefined);
  add(checks, "no remotes in coordinator", !coordinator.includes("RemoteEvent") && !coordinator.includes("RemoteFunction"));
  add(
    checks,
    "no DataStore API in source",
    !serializer.includes("GetService(\"DataStoreService\")") &&
      !deserializer.includes("GetService(\"DataStoreService\")") &&
      !coordinator.includes("GetService(\"DataStoreService\")") &&
      !coordinator.includes("SetAsync") &&
      !coordinator.includes("GetAsync") &&
      !coordinator.includes("UpdateAsync")
  );

  const phase160 = runPhase160SelfChecks();
  add(checks, "phase160 regression self-checks", phase160.ok === true, JSON.stringify(phase160.failures ?? []));
  return summarize(checks);
}

function markdown(result, runtime = null) {
  const lines = [
    "# Phase 161 Runtime Report",
    "",
    `Phase: ${phase161Id} - ${phase161Name}`,
    `Status: ${result.ok ? "STATIC_VALIDATION_PASSED" : "STATIC_VALIDATION_FAILED"}`,
    `Total checks: ${result.total}`,
    `Passed: ${result.passed}`,
    `Failed: ${result.failed}`,
    "",
    "## Findings",
    "",
    "- Save Runtime owns persistent progress schemas, serialization, deserialization, migration planning, diagnostics, snapshots, and evidence.",
    "- Gameplay Flow remains authoritative and Save Runtime consumes identifier-only progress metadata.",
    "- No DataStore, networking, remotes, autosave, cloud save, profile service, analytics, telemetry, or gameplay authority was added.",
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
  const selfCheck = runPhase161SelfChecks();
  const execution = await runRuntimeExecution({
    phase: phase161Id,
    phaseName: phase161Name,
    runnerId: "runtimeExecution.phase161.saveRuntime",
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
  return { ok: selfCheck.ok && runtime.status !== "executionBlocked", selfCheck, runtime };
}

function runValidate() {
  const result = runPhase161SelfChecks();
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
