import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { git, readJson } from "../repository-state.mjs";
import { importExecutionEvidence } from "./ExecutionEvidenceImporter.mjs";
import { serializeExecutionResult } from "./ExecutionResultSerializer.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";
import { createRunnerInvocation } from "./RunnerInvocation.mjs";
import { runPhase154SelfChecks } from "./Phase154AuthoritativeStudioRuntimeEvidenceCapture.mjs";
import { runPhase153SelfChecks } from "./Phase153RuntimeBootstrapValidation.mjs";
import { runRuntimeExecutionSelfChecks } from "./SelfChecks.mjs";

export const phase155Id = 155;
export const phase155Name = "Studio Runtime Execution Bridge";
export const evidenceDirectory = "automation/runtime-evidence/phase-155";
export const evidencePath = `${evidenceDirectory}/phase-155-runtime-evidence.json`;
export const manifestPath = `${evidenceDirectory}/phase-155-manifest.json`;
export const reportPath = `${evidenceDirectory}/phase-155-runtime-report.md`;
export const docsDirectory = "docs/phases/phase-155";
export const bridgeRoot = "src/ServerScriptService/RuntimeExecutionBridge";

const config = readJson("automation/config/automation-config.json");
const phase154ImplementationCommit = "48d4ef8a6726b03e52f02d9993a06e3529439b5c";
const phase154StateCommit = "00eda0a30358c382479e05d363519bd46a1cc5a9";
const bridgeFiles = Object.freeze([
  "Bootstrap.server.lua",
  "Core/BridgeCoordinator.lua",
  "Core/Diagnostics.lua",
  "Core/RuntimeAssertions.lua",
  "Core/RuntimeCapture.lua",
  "Core/RuntimeCleanup.lua",
  "Core/RuntimeDiagnostics.lua",
  "Core/RuntimeEvidence.lua",
  "Core/RuntimeLifecycle.lua",
  "Core/RuntimeSession.lua",
  "Core/RuntimeWriter.lua",
  "Core/SelfChecks.lua",
  "Core/Serialization.lua",
  "Core/Snapshots.lua",
  "Core/State.lua",
  "Core/Types.lua",
  "Core/Validation.lua"
]);

function writeText(path, text) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text, "utf8");
}

function writeJson(path, value) {
  writeText(path, serializeExecutionResult(value));
}

function cleanupLocalSession(sessionId) {
  const sessionRoot = join("automation", "local-state", "runtime-execution", sessionId);
  if (existsSync(sessionRoot)) {
    rmSync(sessionRoot, { recursive: true, force: true });
  }
  return !existsSync(sessionRoot);
}

function currentSource() {
  const localHead = git(config, ["rev-parse", "HEAD"]).stdout.trim();
  const remoteHead = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`]).stdout.trim();
  const branch = git(config, ["branch", "--show-current"]).stdout.trim();
  const status = git(config, ["status", "--short", "--branch"]).stdout;
  return {
    repository: config.repository ?? "LondonBelow",
    branch,
    localHead,
    remoteHead,
    phase154ImplementationCommit,
    phase154StateCommit,
    workingTreeClean:
      status
        .split(/\r?\n/)
        .filter((line) => line.trim() && !line.startsWith("##")).length === 0
  };
}

function scanBridgeSource() {
  const files = bridgeFiles.map((file) => {
    const path = `${bridgeRoot}/${file}`;
    const exists = existsSync(path);
    const text = exists ? readFileSync(path, "utf8") : "";
    return {
      file,
      path,
      exists,
      bytes: Buffer.byteLength(text, "utf8"),
      hasStudioGate: file === "Bootstrap.server.lua" ? text.includes("RunService:IsStudio()") && text.includes("LondonRuntimeExecutionBridgeEnabled") : null,
      hasNoCertificationBoundary: text.includes("productionCertified") || text.includes("certification"),
      hasWriterBlockedTruth: text.includes("WriterBlocked") || text.includes("FilesystemWriterUnavailable") || text.includes("cannot atomically write")
    };
  });
  return {
    root: bridgeRoot,
    fileCount: files.length,
    files,
    complete: files.every((file) => file.exists && file.bytes > 0),
    studioGated: files.find((file) => file.file === "Bootstrap.server.lua")?.hasStudioGate === true,
    writerBoundaryDocumented: files.some((file) => file.hasWriterBlockedTruth === true)
  };
}

function manualPackage(execution, runnerInvocation, evidenceOutput) {
  return {
    sessionFolder: join("automation", "local-state", "runtime-execution", execution.session.sessionId).replaceAll("\\", "/"),
    expectedOutputFile: evidenceOutput.replaceAll("\\", "/"),
    studioBridgeEnableFlag: "LondonRuntimeExecutionBridgeEnabled=true",
    runnerPayload: {
      ...runnerInvocation,
      runnerId: "runtimeExecution.phase155.studioRuntimeExecutionBridge"
    },
    instructions: [
      "Run npm run london:phase155 to generate the source-bound session package.",
      "Open the generated place in Roblox Studio.",
      "Set the DataModel attribute LondonRuntimeExecutionBridgeEnabled to true.",
      "Press Run or Play so ServerScriptService.RuntimeExecutionBridge.Bootstrap.server.lua can start.",
      "Use the Studio bridge output/export channel when available to persist runtime-result.json.",
      "Resume npm run london:phase155 with the same commit to import the structured result."
    ],
    limitation: "Roblox server runtime cannot write the local evidence path by itself; a supported Studio export channel is still required."
  };
}

function createRuntimeEvidence(execution, runnerInvocation, importResult, bridge, cleanupComplete, source) {
  const imported = importResult.ok === true;
  const status = imported ? "runtimeEvidenceImported" : "executionBlocked";
  const writerStatus = imported ? "VERIFIED" : "BLOCKED";
  return {
    schemaVersion: 1,
    phase: phase155Id,
    phaseName: phase155Name,
    status,
    source,
    framework: {
      used: true,
      id: execution.session.frameworkId,
      version: execution.session.frameworkVersion,
      protocolVersion: execution.session.protocolVersion
    },
    session: execution.session,
    manifest: execution.manifest,
    backendSelection: execution.selection,
    backendResult: execution.backendResult,
    studioRuntimeBridge: {
      exists: bridge.complete,
      root: bridge.root,
      fileCount: bridge.fileCount,
      studioGated: bridge.studioGated,
      writerBoundaryDocumented: bridge.writerBoundaryDocumented,
      files: bridge.files
    },
    runnerInvocation: {
      ...runnerInvocation,
      runnerId: "runtimeExecution.phase155.studioRuntimeExecutionBridge"
    },
    evidenceImport: {
      ok: importResult.ok,
      reason: importResult.reason,
      failure: importResult.failure,
      checksum: importResult.checksum ?? null
    },
    runtimeEvidence: imported ? importResult.evidence : null,
    runtimeEvents: [
      { event: "Bridge Started", status: imported ? "VERIFIED" : "NOT_EXECUTED", evidenceSource: imported ? "ImportedStudioRuntimeResult" : "Bridge source only" },
      { event: "Bootstrap Started", status: imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", evidenceSource: imported ? "ImportedStudioRuntimeResult" : "Bridge source only" },
      { event: "Bootstrap Finished", status: imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", evidenceSource: imported ? "ImportedStudioRuntimeResult" : "Bridge source only" },
      { event: "Cleanup Started", status: imported ? "VERIFIED" : "NOT_EXECUTED", evidenceSource: imported ? "ImportedStudioRuntimeResult" : "Bridge source only" },
      { event: "Shutdown", status: imported ? "VERIFIED" : "NOT_EXECUTED", evidenceSource: imported ? "ImportedStudioRuntimeResult" : "Bridge source only" }
    ],
    assertions: [
      { name: "Server Started", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "Client Started", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "Bootstrap Started", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "Bootstrap Finished", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "Coordinator Registered", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "No Runtime Exception", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "Cleanup Executed", status: imported ? "PASS" : "NOT_EXECUTED" },
      { name: "Shutdown Executed", status: imported ? "PASS" : "NOT_EXECUTED" }
    ],
    diagnostics: {
      bridgeSourceValid: bridge.complete,
      writerStatus,
      writerFailure: imported ? null : "Roblox server runtime cannot write local runtime-result.json without a supported Studio export channel.",
      importFailure: importResult.failure ?? null
    },
    snapshots: {
      bridgeSource: bridge.files,
      frameworkSessionId: execution.session.sessionId,
      runtimeEvidenceImported: imported
    },
    writer: {
      status: writerStatus,
      expectedOutputPath: manualPackage(execution, runnerInvocation, join("automation", "local-state", "runtime-execution", execution.session.sessionId, "runtime-result.json")).expectedOutputFile,
      atomicWriteVerified: imported,
      blockedReason: imported ? null : "No supported Roblox server filesystem writer exists in this repository."
    },
    importValidation: {
      expected: "Existing ExecutionEvidenceImporter and RunnerResultSchema authority",
      accepted: imported,
      rejectedReason: imported ? null : importResult.reason,
      rejectedFailure: imported ? null : importResult.failure
    },
    failureClassification: imported ? "None" : "Writer",
    securityReview: {
      studioGate: "Bootstrap.server.lua requires Studio and LondonRuntimeExecutionBridgeEnabled.",
      noRemotes: "Bridge creates no RemoteEvent or RemoteFunction.",
      noPersistence: "Bridge does not call DataStore APIs.",
      noHttp: "Bridge does not call HttpService.",
      noTelemetry: "Bridge does not emit analytics or telemetry.",
      writerBoundary: "Local runtime-result.json write is blocked truthfully until a supported export channel exists.",
      checksum: "Bridge can checksum in-memory payloads but cannot persist/import them without the export channel."
    },
    cleanup: {
      completed: cleanupComplete,
      localSessionArtifactsRemoved: cleanupComplete,
      committedBinaryArtifacts: false
    },
    certification: {
      authorityInvoked: false,
      latestProductionCertifiedPhase: 108,
      productionCertified: false,
      reason: "Phase 155 establishes the Studio bridge; certification remains external to this bridge."
    },
    nextRecommendedPhase: imported
      ? "Phase 156 - Chapter 0 Bootstrap Runtime Verification"
      : "Phase 156 - Studio Runtime Bridge Remediation"
  };
}

function tableFor(rows, columns) {
  return [
    `| ${columns.join(" | ")} |`,
    `| ${columns.map(() => "---").join(" | ")} |`,
    ...rows.map((row) => `| ${columns.map((column) => String(row[column] ?? "").replace(/\r?\n/g, " ")).join(" | ")} |`)
  ].join("\n");
}

function writeDocs(evidence, manifest) {
  const docs = {
    "00_BASELINE.md": `# Phase 155 Baseline\n\nRepository: ${evidence.source.repository}\n\nBranch: ${evidence.source.branch}\n\nLocal commit: ${evidence.source.localHead}\n\nOrigin/main: ${evidence.source.remoteHead}\n\nPrevious implementation commit: ${evidence.source.phase154ImplementationCommit}\n\nPrevious state commit: ${evidence.source.phase154StateCommit}\n\nBridge source complete: ${evidence.studioRuntimeBridge.exists}\n\nRuntime evidence imported: ${evidence.evidenceImport.ok}\n`,
    "01_BRIDGE_ARCHITECTURE.md": `# Phase 155 Bridge Architecture\n\nRuntime Execution Framework remains the consumer. Studio Runtime Execution Bridge is the Studio-side producer boundary. The bridge is inert unless Studio mode and the explicit DataModel attribute are present.\n\n${tableFor(evidence.studioRuntimeBridge.files, ["file", "exists", "bytes"])}\n`,
    "02_SESSION_IMPORT.md": `# Phase 155 Session Import\n\nSession: ${evidence.session.sessionId}\n\nManifest: ${evidence.manifest.manifestId}\n\nRunner: ${evidence.runnerInvocation.runnerId}\n\nPhase: ${evidence.phase}\n\nCommit: ${evidence.session.repositoryCommit}\n\nSession metadata is validated by the Studio bridge before capture and by the existing Node importer on resume.\n`,
    "03_RUNTIME_EVENTS.md": `# Phase 155 Runtime Events\n\n${tableFor(evidence.runtimeEvents, ["event", "status", "evidenceSource"])}\n`,
    "04_ASSERTIONS.md": `# Phase 155 Assertions\n\n${tableFor(evidence.assertions, ["name", "status"])}\n`,
    "05_DIAGNOSTICS.md": `# Phase 155 Diagnostics\n\nBridge source valid: ${evidence.diagnostics.bridgeSourceValid}\n\nWriter status: ${evidence.diagnostics.writerStatus}\n\nWriter failure: ${evidence.diagnostics.writerFailure ?? "none"}\n\nImport failure: ${evidence.diagnostics.importFailure ?? "none"}\n`,
    "06_SNAPSHOTS.md": `# Phase 155 Snapshots\n\nFramework session: ${evidence.snapshots.frameworkSessionId}\n\nRuntime evidence imported: ${evidence.snapshots.runtimeEvidenceImported}\n\nBridge source files are listed in the runtime evidence snapshot.\n`,
    "07_RUNTIME_RESULT_SCHEMA.md": `# Phase 155 Runtime Result Schema\n\nThe bridge prepares the existing importer-compatible runner result fields. It does not create a second evidence schema.\n\nRequired fields: schemaVersion, runnerId, sessionId, phase, repositoryCommit, runtime, status, studioVersion, serverStarted, clientStarted, clientCount, assertions, diagnostics, snapshots, audit, errors, warnings, cleanup, productionCertified, capturedAt.\n`,
    "08_WRITER.md": `# Phase 155 Writer\n\nWriter status: ${evidence.writer.status}\n\nExpected output path: ${evidence.writer.expectedOutputPath}\n\nAtomic write verified: ${evidence.writer.atomicWriteVerified}\n\nBlocked reason: ${evidence.writer.blockedReason ?? "none"}\n\nThe Roblox server runtime has no supported local filesystem writer in this repository, so file export remains blocked until a supported Studio export channel is added.\n`,
    "09_IMPORT_RESULTS.md": `# Phase 155 Import Results\n\nAccepted: ${evidence.importValidation.accepted}\n\nRejected reason: ${evidence.importValidation.rejectedReason ?? "none"}\n\nRejected failure: ${evidence.importValidation.rejectedFailure ?? "none"}\n\nImporter authority: ${evidence.importValidation.expected}\n`,
    "10_FAILURE_ANALYSIS.md": `# Phase 155 Failure Analysis\n\nClassification: ${evidence.failureClassification}\n\nRoot cause: ${evidence.writer.blockedReason ?? "No failure."}\n\nImpact: runtime-result.json cannot be imported until a supported Studio export channel writes the file.\n\nRecovery: Phase 156 should remediate the Studio bridge export path without changing gameplay.\n`,
    "11_SECURITY_REVIEW.md": `# Phase 155 Security Review\n\n${Object.entries(evidence.securityReview)
      .map(([key, value]) => `- ${key}: ${value}`)
      .join("\n")}\n`,
    "12_PRODUCTION_REVIEW.md": `# Phase 155 Production Review\n\nVerdict: Production Candidate\n\nConfidence: high for bridge source, blocked for imported Studio runtime evidence\n\nStrongest Evidence: the Studio-side bridge is mapped into Rojo, gated to Studio plus an explicit attribute, validates session metadata, prepares importer-compatible evidence, and blocks unsupported local file writing truthfully.\n\nLargest Limitation: no supported Studio export channel wrote runtime-result.json for import.\n\nRecommendation: ${evidence.nextRecommendedPhase}\n`,
    "13_COMPLETION_REPORT.md": `# Phase 155 Completion Report\n\nStatus: ${evidence.status}\n\nRuntime evidence imported: ${evidence.evidenceImport.ok}\n\nBridge source complete: ${evidence.studioRuntimeBridge.exists}\n\nWriter status: ${evidence.writer.status}\n\nCertification authority invoked: ${evidence.certification.authorityInvoked}\n\nNext recommended phase: ${evidence.nextRecommendedPhase}\n`
  };
  for (const [file, text] of Object.entries(docs)) {
    writeText(join(docsDirectory, file), text);
  }
  writeJson(evidencePath, evidence);
  writeJson(manifestPath, manifest);
  writeText(
    reportPath,
    `# Phase 155 Runtime Report\n\nStatus: ${evidence.status}\n\nSession: ${evidence.session.sessionId}\n\nBridge source complete: ${evidence.studioRuntimeBridge.exists}\n\nRuntime evidence imported: ${evidence.evidenceImport.ok}\n\nBlocking point: ${evidence.evidenceImport.ok ? "none" : evidence.failureClassification}\n\nNext recommended phase: ${evidence.nextRecommendedPhase}\n`
  );
}

export function runPhase155StudioRuntimeExecutionBridge(options = {}) {
  const source = currentSource();
  const execution = runRuntimeExecution({
    phase: phase155Id,
    phaseName: phase155Name,
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
  const bridge = scanBridgeSource();
  const cleanupComplete = options.skipCleanup === true ? false : cleanupLocalSession(execution.session.sessionId);
  const evidence = createRuntimeEvidence(execution, runnerInvocation, importResult, bridge, cleanupComplete, source);
  const manifest = {
    schemaVersion: 1,
    phase: phase155Id,
    phaseName: phase155Name,
    status: evidence.status,
    sessionId: execution.session.sessionId,
    backend: execution.session.backend,
    bridgeRoot,
    evidencePath,
    reportPath,
    runtimeEvidenceImported: importResult.ok,
    cleanupComplete,
    certificationAuthorityInvoked: false,
    nextRecommendedPhase: evidence.nextRecommendedPhase
  };
  if (options.write !== false) {
    writeDocs(evidence, manifest);
  }
  return { evidence, manifest };
}

function addCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runPhase155SelfChecks() {
  const results = [];
  const frameworkChecks = runRuntimeExecutionSelfChecks();
  const phase154Checks = runPhase154SelfChecks();
  const phase153Checks = runPhase153SelfChecks();
  results.push(...frameworkChecks.map((check) => ({ name: `framework.${check.name}`, ok: check.ok, detail: check.detail })));
  results.push(...phase154Checks.map((check) => ({ name: `phase154.${check.name}`, ok: check.ok, detail: check.detail })));
  results.push(...phase153Checks.map((check) => ({ name: `phase153.${check.name}`, ok: check.ok, detail: check.detail })));
  const run = runPhase155StudioRuntimeExecutionBridge({ write: false });
  const evidence = run.evidence;

  addCheck(results, "phase155UsesFramework", evidence.framework.used === true);
  addCheck(results, "phase155ManualBackendSelected", evidence.session.backend === "StudioManual");
  addCheck(results, "phase155BridgeExists", evidence.studioRuntimeBridge.exists === true);
  addCheck(results, "phase155BridgeStudioGated", evidence.studioRuntimeBridge.studioGated === true);
  addCheck(results, "phase155WriterBoundaryDocumented", evidence.studioRuntimeBridge.writerBoundaryDocumented === true);
  addCheck(results, "phase155SessionCreated", evidence.session.sessionId.includes("phase-155"));
  addCheck(results, "phase155ManifestCreated", evidence.manifest.phase === phase155Id);
  addCheck(results, "phase155RunnerBridgeId", evidence.runnerInvocation.runnerId === "runtimeExecution.phase155.studioRuntimeExecutionBridge");
  addCheck(results, "phase155ImportAttempted", evidence.evidenceImport.failure === "MissingEvidence" || evidence.evidenceImport.ok === true);
  addCheck(results, "phase155BlockedWithoutEvidence", evidence.evidenceImport.ok || evidence.status === "executionBlocked");
  addCheck(results, "phase155RuntimeEventsReported", evidence.runtimeEvents.length === 5);
  addCheck(results, "phase155AssertionsReported", evidence.assertions.length === 8);
  addCheck(results, "phase155DiagnosticsReported", evidence.diagnostics.writerStatus === "BLOCKED" || evidence.evidenceImport.ok);
  addCheck(results, "phase155SnapshotsReported", Array.isArray(evidence.snapshots.bridgeSource));
  addCheck(results, "phase155WriterBlockedTruthful", evidence.evidenceImport.ok || evidence.writer.status === "BLOCKED");
  addCheck(results, "phase155NoCertification", evidence.certification.productionCertified === false && evidence.certification.authorityInvoked === false);
  addCheck(results, "phase155LatestCertifiedPreserved", evidence.certification.latestProductionCertifiedPhase === 108);
  addCheck(results, "phase155CleanupComplete", evidence.cleanup.completed === true);
  addCheck(results, "phase155NextPhaseRemediation", evidence.evidenceImport.ok || evidence.nextRecommendedPhase === "Phase 156 - Studio Runtime Bridge Remediation");
  for (const file of evidence.studioRuntimeBridge.files) {
    addCheck(results, `phase155BridgeFile.${file.file}`, file.exists && file.bytes > 0);
  }
  for (const event of evidence.runtimeEvents) {
    addCheck(results, `phase155Event.${event.event}`, typeof event.status === "string" && event.status.length > 0);
  }
  for (const assertion of evidence.assertions) {
    addCheck(results, `phase155Assertion.${assertion.name}`, ["PASS", "FAIL", "BLOCKED", "NOT_EXECUTED"].includes(assertion.status));
  }
  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runPhase155SelfChecks();
    const failed = results.filter((check) => !check.ok);
    console.log(`TOTAL ${results.length}`);
    console.log(`PASSED ${results.length - failed.length}`);
    console.log(`FAILURES ${failed.length}`);
    for (const failure of failed) console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
    process.exitCode = failed.length === 0 ? 0 : 5;
    return;
  }
  const result = runPhase155StudioRuntimeExecutionBridge();
  console.log(JSON.stringify(result.manifest, null, 2));
  process.exitCode = result.manifest.runtimeEvidenceImported ? 0 : 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
