import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { git, readJson } from "../repository-state.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";
import { importExecutionEvidence } from "./ExecutionEvidenceImporter.mjs";
import { createRunnerInvocation } from "./RunnerInvocation.mjs";
import { serializeExecutionResult } from "./ExecutionResultSerializer.mjs";
import { runRuntimeExecutionSelfChecks } from "./SelfChecks.mjs";

export const phase153Id = 153;
export const phase153Name = "Chapter 0 Runtime Execution & Bootstrap Validation";
export const evidenceDirectory = "automation/runtime-evidence/phase-153";
export const evidencePath = `${evidenceDirectory}/phase-153-runtime-evidence.json`;
export const manifestPath = `${evidenceDirectory}/phase-153-manifest.json`;
export const reportPath = `${evidenceDirectory}/phase-153-runtime-report.md`;

const config = readJson("automation/config/automation-config.json");

function writeJson(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, serializeExecutionResult(value), "utf8");
}

function cleanupLocalSession(sessionId) {
  const sessionRoot = join("automation", "local-state", "runtime-execution", sessionId);
  if (existsSync(sessionRoot)) {
    rmSync(sessionRoot, { recursive: true, force: true });
  }
  return !existsSync(sessionRoot);
}

function currentSource() {
  const localHead = git(config, ["rev-parse", "HEAD"]);
  const remoteHead = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`]);
  const branch = git(config, ["branch", "--show-current"]);
  const status = git(config, ["status", "--short", "--branch"]);
  return {
    branch: branch.stdout.trim(),
    localHead: localHead.stdout.trim(),
    remoteHead: remoteHead.stdout.trim(),
    workingTreeClean:
      status.stdout
        .split(/\r?\n/)
        .filter((line) => line.trim() && !line.startsWith("##")).length === 0
  };
}

function bootstrapSubsystems() {
  return [
    "CoreBootstrap",
    "Governance",
    "ContractRegistry",
    "Diagnostics",
    "Snapshots",
    "Observation",
    "Interaction",
    "Presentation",
    "Chapter0Home"
  ].map((subsystem) => ({
    subsystem,
    initializationStarted: false,
    initializationCompleted: false,
    durationMilliseconds: null,
    dependencies: [],
    status: "BLOCKED",
    evidenceSource: "RuntimeExecutionFrameworkManualBackend",
    confidence: "blockedBeforeRuntime",
    failureReason: "No Studio Play/Run structured result was imported.",
    nextAction: "Run the generated manual Studio workflow and import the source-bound result."
  }));
}

function coordinatorGraph() {
  return [
    ["CoreBootstrap", "RuntimeExecutionFramework"],
    ["Governance", "CoreBootstrap"],
    ["Diagnostics", "CoreBootstrap"],
    ["Observation", "Governance"],
    ["Interaction", "Observation"],
    ["Presentation", "Governance"],
    ["Chapter0HomeCoordinator", "Observation, Interaction, Presentation"]
  ].map(([coordinator, dependencies], index) => ({
    coordinator,
    owner: coordinator === "Chapter0HomeCoordinator" ? "Chapter0Home" : "Core",
    initializationOrder: index + 1,
    dependencies: dependencies.split(", ").filter(Boolean),
    dependents: [],
    startupDurationMilliseconds: null,
    failureState: "BLOCKED",
    recoveryPossible: true,
    verified: false,
    blocked: true,
    notExecuted: true
  }));
}

function timeline(backendResult, importResult) {
  return [
    ["Execution Requested", "VERIFIED", "Runtime Execution Framework invoked for Phase 153."],
    ["Environment Validated", "VERIFIED", "Repository source state captured."],
    ["Backend Selected", "VERIFIED", "StudioManual selected through backend registry."],
    ["Manifest Generated", "VERIFIED", "Framework manifest generated."],
    ["Place Prepared", backendResult?.assertions?.[0]?.status === "PASS" ? "VERIFIED" : "BLOCKED", "Manual backend place preparation attempted."],
    ["Studio Opened", "BLOCKED", "Manual action was not performed by automation."],
    ["Play Started", "BLOCKED", "No Studio Play/Run result was imported."],
    ["Server Bootstrap", "BLOCKED", "No server runtime evidence imported."],
    ["Client Bootstrap", "BLOCKED", "No client runtime evidence imported."],
    ["Core Bootstrap", "BLOCKED", "No bootstrap runtime evidence imported."],
    ["Governance Bootstrap", "BLOCKED", "No governance runtime evidence imported."],
    ["Diagnostics Bootstrap", "BLOCKED", "No diagnostics runtime evidence imported."],
    ["Observation Bootstrap", "BLOCKED", "No observation runtime evidence imported."],
    ["Presentation Bootstrap", "BLOCKED", "No presentation runtime evidence imported."],
    ["Chapter0 Bootstrap", "BLOCKED", "No Chapter0 runtime evidence imported."],
    ["Evidence Import", importResult.ok ? "VERIFIED" : "BLOCKED", importResult.reason ?? "No evidence imported."],
    ["Cleanup", "VERIFIED", "Generated local session artifacts cleaned after Phase 153 smoke attempt."]
  ].map(([name, status, detail], index) => ({ index: index + 1, name, status, detail }));
}

export function runPhase153RuntimeBootstrapValidation(options = {}) {
  const source = currentSource();
  const execution = runRuntimeExecution({
    phase: phase153Id,
    phaseName: phase153Name,
    requestedBackend: "StudioManual",
    runtimeEvidenceRequired: true,
    cwd: process.cwd()
  });
  const context = {
    sessionId: execution.session.sessionId,
    configuration: execution.configuration,
    environment: execution.environment,
    backend: execution.backend,
    timestamp: execution.timestamp
  };
  const evidenceOutput = join("automation", "local-state", "runtime-execution", execution.session.sessionId, "runtime-result.json");
  const runnerInvocation = createRunnerInvocation(context, evidenceOutput);
  const importResult = importExecutionEvidence(evidenceOutput, context);
  const cleanupComplete = options.skipCleanup === true ? false : cleanupLocalSession(execution.session.sessionId);
  const finalStatus = importResult.ok ? "runtimeEvidenceImported" : "executionBlocked";
  const evidence = {
    schemaVersion: 1,
    phase: phase153Id,
    phaseName: phase153Name,
    status: finalStatus,
    source,
    session: execution.session,
    manifest: execution.manifest,
    backendSelection: execution.selection,
    backendResult: execution.backendResult,
    runnerInvocation,
    evidenceImport: {
      ok: importResult.ok,
      reason: importResult.reason,
      failure: importResult.failure,
      checksum: importResult.checksum ?? null
    },
    runtimeTimeline: timeline(execution.backendResult, importResult),
    bootstrapSubsystems: bootstrapSubsystems(),
    coordinatorGraph: coordinatorGraph(),
    failureClassification: importResult.ok ? "None" : "Evidence",
    runtimeScorecard: {
      scoredItems: [],
      blockedItems: ["Studio Opened", "Play Started", "Server Bootstrap", "Client Bootstrap", "Chapter0 Bootstrap"],
      rule: "Only executed runtime facts may be scored."
    },
    cleanup: {
      completed: cleanupComplete,
      localSessionArtifactsRemoved: cleanupComplete,
      committedBinaryArtifacts: false
    },
    certification: {
      authorityInvoked: false,
      latestProductionCertifiedPhase: 108,
      productionCertified: false
    },
    nextAction: importResult.ok
      ? "Review imported runtime evidence before certification eligibility."
      : "Run the manual Studio workflow generated by the framework and import the session-bound structured result."
  };

  const manifest = {
    schemaVersion: 1,
    phase: phase153Id,
    phaseName: phase153Name,
    status: finalStatus,
    evidencePath,
    reportPath,
    sessionId: execution.session.sessionId,
    backend: execution.session.backend,
    cleanupComplete,
    runtimeEvidenceImported: importResult.ok,
    certificationAuthorityInvoked: false
  };

  if (options.write !== false) {
    writeJson(evidencePath, evidence);
    writeJson(manifestPath, manifest);
    writeFileSync(
      reportPath,
      `# Phase 153 Runtime Report\n\nStatus: ${finalStatus}\n\nSession: ${execution.session.sessionId}\n\nBackend: ${execution.session.backend}\n\nRuntime evidence imported: ${importResult.ok}\n\nBlocking point: ${importResult.ok ? "none" : "Evidence Import"}\n\nNext action: ${evidence.nextAction}\n`,
      "utf8"
    );
  }

  return { evidence, manifest };
}

export function runPhase153SelfChecks() {
  const results = [];
  const frameworkChecks = runRuntimeExecutionSelfChecks();
  results.push(...frameworkChecks.map((check) => ({ name: `framework.${check.name}`, ok: check.ok, detail: check.detail })));
  const run = runPhase153RuntimeBootstrapValidation({ write: false });
  results.push({ name: "phase153UsesRuntimeExecutionFramework", ok: run.evidence.session.frameworkId === "london.runtimeExecutionFramework", detail: "" });
  results.push({ name: "phase153BackendSelected", ok: run.evidence.session.backend === "StudioManual", detail: "" });
  results.push({ name: "phase153ManifestGenerated", ok: run.evidence.manifest.phase === phase153Id, detail: "" });
  results.push({ name: "phase153PlacePreparedOrBlocked", ok: ["waitingForManualAction", "failed"].includes(run.evidence.backendResult.status), detail: "" });
  results.push({ name: "phase153EvidenceImportClassified", ok: run.evidence.evidenceImport.failure === "MissingEvidence" || run.evidence.evidenceImport.ok === true, detail: "" });
  results.push({ name: "phase153TimelineHasBlockingPoint", ok: run.evidence.runtimeTimeline.some((entry) => entry.status === "BLOCKED"), detail: "" });
  results.push({ name: "phase153BootstrapSubsystemsReported", ok: run.evidence.bootstrapSubsystems.length >= 9, detail: "" });
  results.push({ name: "phase153CoordinatorGraphReported", ok: run.evidence.coordinatorGraph.length >= 7, detail: "" });
  results.push({ name: "phase153NoCertification", ok: run.evidence.certification.authorityInvoked === false, detail: "" });
  results.push({ name: "phase153CleanupCompleted", ok: run.evidence.cleanup.completed === true, detail: "" });
  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runPhase153SelfChecks();
    const failed = results.filter((check) => !check.ok);
    console.log(`TOTAL ${results.length}`);
    console.log(`PASSED ${results.length - failed.length}`);
    console.log(`FAILURES ${failed.length}`);
    for (const failure of failed) console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
    process.exitCode = failed.length === 0 ? 0 : 5;
    return;
  }

  const result = runPhase153RuntimeBootstrapValidation();
  console.log(JSON.stringify(result.manifest, null, 2));
  process.exitCode = result.manifest.runtimeEvidenceImported ? 0 : 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
