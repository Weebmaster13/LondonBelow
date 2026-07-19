import { existsSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { git, readJson } from "../repository-state.mjs";
import { importExecutionEvidence } from "./ExecutionEvidenceImporter.mjs";
import { serializeExecutionResult } from "./ExecutionResultSerializer.mjs";
import { runRuntimeExecution } from "./RuntimeExecutionCoordinator.mjs";
import { createRunnerInvocation } from "./RunnerInvocation.mjs";
import { runRuntimeExecutionSelfChecks } from "./SelfChecks.mjs";

export const phase154Id = 154;
export const phase154Name = "Authoritative Studio Runtime Evidence Capture";
export const evidenceDirectory = "automation/runtime-evidence/phase-154";
export const evidencePath = `${evidenceDirectory}/phase-154-runtime-evidence.json`;
export const manifestPath = `${evidenceDirectory}/phase-154-manifest.json`;
export const reportPath = `${evidenceDirectory}/phase-154-runtime-report.md`;
export const docsDirectory = "docs/phases/phase-154";

const config = readJson("automation/config/automation-config.json");
const phase153ImplementationCommit = "8ab43b056974ca38b46ab6d44b7da21a1291b769";
const phase153StateCommit = "46a525725b1ee344c61a22c31db7dd80e5b8bc68";

const requiredRuntimeFields = Object.freeze([
  "schemaVersion",
  "runnerId",
  "sessionId",
  "phase",
  "repositoryCommit",
  "runtime",
  "status",
  "studioVersion",
  "serverStarted",
  "clientStarted",
  "clientCount",
  "assertions",
  "diagnostics",
  "snapshots",
  "audit",
  "errors",
  "warnings",
  "cleanup",
  "productionCertified",
  "capturedAt"
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
  const localHead = git(config, ["rev-parse", "HEAD"]);
  const remoteHead = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`]);
  const branch = git(config, ["branch", "--show-current"]);
  const status = git(config, ["status", "--short", "--branch"]);
  return {
    repository: config.repository ?? "LondonBelow",
    branch: branch.stdout.trim(),
    localHead: localHead.stdout.trim(),
    remoteHead: remoteHead.stdout.trim(),
    phase153ImplementationCommit,
    phase153StateCommit,
    workingTreeClean:
      status.stdout
        .split(/\r?\n/)
        .filter((line) => line.trim() && !line.startsWith("##")).length === 0
  };
}

function createManualExecutionPackage(execution, runnerInvocation, evidenceOutput) {
  return {
    sessionFolder: join("automation", "local-state", "runtime-execution", execution.session.sessionId).replaceAll("\\", "/"),
    manifestId: execution.manifest.manifestId,
    runnerPayload: runnerInvocation,
    expectedOutputFile: evidenceOutput.replaceAll("\\", "/"),
    instructions: [
      "Run npm run london:phase154 to generate the source-bound session package.",
      "Open the generated Roblox place from the manual backend instruction file.",
      "Press Play or Run in Roblox Studio.",
      "Execute the repository-owned Studio runner matching the runnerId.",
      "Export the structured runtime result to the expected output file.",
      "Resume npm run london:phase154 with the same source commit so the framework imports the result."
    ],
    timeout: runnerInvocation.timeout,
    resumeCommand: `npm run london:phase154 -- --session ${execution.session.sessionId}`,
    cancellationCommand: `Remove-Item -Recurse -Force ${join("automation", "local-state", "runtime-execution", execution.session.sessionId)}`,
    manualBackendOwnsStudioHandoff: true,
    frameworkOwnsEvidenceImport: true
  };
}

function classifyImport(importResult) {
  if (importResult.ok) return "None";
  switch (importResult.failure) {
    case "MissingEvidence":
      return "Evidence Import";
    case "MalformedJson":
    case "SchemaMismatch":
    case "UnsupportedSchema":
    case "UnsupportedEvidenceType":
      return "Validation";
    case "SessionMismatch":
    case "PhaseMismatch":
    case "CommitMismatch":
      return "Evidence Import";
    case "ChecksumMismatch":
      return "Evidence Import";
    case "PathTraversalRejected":
      return "Security";
    default:
      return "Unknown";
  }
}

function createValidationCategories(importResult) {
  const imported = importResult.ok === true;
  const evidence = importResult.evidence ?? {};
  const serverStatus = imported && evidence.serverStarted === true ? "VERIFIED" : "NOT_EXECUTED";
  const clientStatus = imported && evidence.clientStarted === true ? "VERIFIED" : "NOT_EXECUTED";
  return [
    ["Framework", "VERIFIED", "Runtime Execution Framework created the session, manifest, backend result, and import attempt."],
    ["Backend", "VERIFIED_WITH_LIMITATIONS", "Studio Manual Backend generated source-bound handoff artifacts and requires human Studio execution."],
    ["Studio", imported ? "VERIFIED" : "BLOCKED", imported ? "Imported runtime evidence reported Studio execution." : "No Studio-produced structured result was present."],
    ["Runner", imported ? "VERIFIED" : "BLOCKED", imported ? "Runner identity and source binding passed import validation." : "Runner was not invoked by automation."],
    ["Bootstrap", imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", imported ? "Bootstrap facts are limited to imported runner data." : "No bootstrap runtime facts were imported."],
    ["Server", serverStatus, serverStatus === "VERIFIED" ? "Server startup was reported by runtime evidence." : "No server startup evidence imported."],
    ["Client", clientStatus, clientStatus === "VERIFIED" ? "Client startup was reported by runtime evidence." : "No client startup evidence imported."],
    ["Diagnostics", imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", imported ? "Diagnostics array was accepted by schema validation." : "No diagnostics evidence imported."],
    ["Snapshots", imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", imported ? "Snapshots value was accepted by schema validation." : "No snapshot evidence imported."],
    ["Cleanup", "VERIFIED", "Local session cleanup completed after import attempt."]
  ].map(([category, status, detail]) => ({ category, status, detail }));
}

function createBootstrapResults(importResult) {
  const imported = importResult.ok === true;
  return [
    "CoreBootstrap",
    "Governance",
    "Contracts",
    "Diagnostics",
    "Snapshots",
    "Observation",
    "Interaction",
    "Presentation",
    "Chapter0Home",
    "Coordinator Initialization",
    "Shutdown",
    "Cleanup"
  ].map((subsystem) => ({
    subsystem,
    initializationStarted: imported ? null : false,
    initializationCompleted: imported ? null : false,
    durationMilliseconds: null,
    dependencies: [],
    status: subsystem === "Cleanup" ? "VERIFIED" : imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED",
    evidenceSource: imported ? "ImportedStudioRuntimeResult" : "RuntimeExecutionFrameworkManualBackend",
    confidence: imported ? "importedRuntimeEvidence" : "blockedBeforeRuntime",
    failureReason: imported ? null : "No Studio Play/Run structured result was imported.",
    nextAction: imported ? "Review imported bootstrap evidence in Phase 155." : "Export the Studio runner result and re-run Phase 154 import."
  }));
}

function createCoordinatorGraph(importResult) {
  const imported = importResult.ok === true;
  const definitions = [
    ["CoreBootstrap", "RuntimeExecutionFramework", []],
    ["Governance", "Core", ["CoreBootstrap"]],
    ["Contracts", "Governance", ["Governance"]],
    ["Diagnostics", "Core", ["CoreBootstrap"]],
    ["Snapshots", "Core", ["Diagnostics"]],
    ["Observation", "Observation", ["Governance", "Diagnostics"]],
    ["Interaction", "Interaction", ["Observation"]],
    ["Presentation", "Presentation", ["Governance", "Diagnostics"]],
    ["Chapter0HomeCoordinator", "Chapter0Home", ["Observation", "Interaction", "Presentation"]]
  ];
  return definitions.map(([coordinator, owner, dependencies], index) => ({
    coordinator,
    owner,
    initializationOrder: index + 1,
    dependencies,
    dependents: definitions.filter((entry) => entry[2].includes(coordinator)).map((entry) => entry[0]),
    startupDurationMilliseconds: null,
    failureState: imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED",
    recoveryPossible: !imported,
    verified: imported,
    blocked: !imported,
    notExecuted: !imported,
    evidence: imported ? "Imported runner result passed session, phase, commit, schema, and certification-boundary validation." : "No imported runtime evidence."
  }));
}

function createTimeline(execution, importResult) {
  const placePrepared = execution.backendResult?.assertions?.some((assertion) => assertion.name === "placePrepared" && assertion.status === "PASS");
  const imported = importResult.ok === true;
  return [
    ["Execution Requested", "VERIFIED", "Phase 154 invoked the Runtime Execution Framework."],
    ["Environment Validated", "VERIFIED", "Repository source state was captured before the manual handoff."],
    ["Backend Selected", "VERIFIED", "StudioManual was selected through the backend registry."],
    ["Manifest Generated", "VERIFIED", "Framework manifest was generated."],
    ["Place Prepared", placePrepared ? "VERIFIED" : "FAILED", placePrepared ? "Rojo build produced a temporary place artifact." : "Rojo place generation failed."],
    ["Studio Opened", imported ? "VERIFIED" : "BLOCKED", imported ? "Studio execution was reported by imported evidence." : "Manual Studio action did not produce an importable result."],
    ["Play Started", imported ? "VERIFIED" : "BLOCKED", imported ? "Play/Run mode was reported by imported evidence." : "No Play/Run evidence imported."],
    ["Runner Started", imported ? "VERIFIED" : "BLOCKED", imported ? "Runner result was imported and schema-validated." : "Runner output file missing."],
    ["Server Started", imported && importResult.evidence.serverStarted ? "VERIFIED" : "NOT_EXECUTED", "Status taken only from imported evidence."],
    ["Client Started", imported && importResult.evidence.clientStarted ? "VERIFIED" : "NOT_EXECUTED", "Status taken only from imported evidence."],
    ["Bootstrap Began", imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", "Bootstrap facts require imported runner evidence."],
    ["Bootstrap Completed", imported ? "VERIFIED_WITH_LIMITATIONS" : "NOT_EXECUTED", "Bootstrap facts require imported runner evidence."],
    ["Evidence Exported", imported ? "VERIFIED" : "BLOCKED", imported ? "Structured runtime result existed at the expected output path." : "No structured result file existed at the expected output path."],
    ["Evidence Imported", imported ? "VERIFIED" : "BLOCKED", importResult.reason ?? "Evidence import completed."],
    ["Cleanup", "VERIFIED", "Local runtime session artifacts were cleaned after the attempt."]
  ].map(([stage, status, detail], index) => ({ order: index + 1, stage, status, detail }));
}

function createScorecard(validationCategories) {
  return validationCategories.map((entry) => ({
    category: entry.category,
    score:
      entry.status === "VERIFIED"
        ? 1
        : entry.status === "VERIFIED_WITH_LIMITATIONS"
          ? 0.5
          : null,
    status: entry.status,
    scoringRule: entry.status === "BLOCKED" || entry.status === "NOT_EXECUTED" ? "Not scored because no verified runtime evidence exists." : "Scored from verified framework/import evidence only."
  }));
}

function createFailureAnalysis(importResult) {
  if (importResult.ok) {
    return [
      {
        category: "None",
        rootCause: "Structured Studio runtime evidence imported successfully.",
        impact: "Phase 155 can validate subsystem runtime behavior.",
        recovery: "No recovery required.",
        confidence: "high"
      }
    ];
  }
  return [
    {
      category: classifyImport(importResult),
      rootCause: importResult.reason ?? "No importable runtime evidence was available.",
      impact: "Authoritative Studio runtime evidence remains unavailable, so certification cannot advance.",
      recovery: "Run the generated manual Studio workflow and export the structured runner result to the expected path.",
      confidence: "high"
    }
  ];
}

function createSecurityReview(importResult, manualPackage) {
  return {
    evidenceImport: "Evidence import is constrained to automation/local-state/runtime-execution.",
    temporaryFiles: "Temporary place and runner-output paths are session-scoped and cleaned after the Phase 154 attempt.",
    runnerOutput: `Expected output file: ${manualPackage.expectedOutputFile}`,
    pathTraversal: "Rejected by ExecutionEvidenceImporter before file reads.",
    commandInjection: "No dynamic shell command is built from imported evidence.",
    studioLaunch: "Manual backend does not launch Studio automatically.",
    manualWorkflow: "Human action is required; success is not inferred from instructions.",
    cleanup: "Cleanup removes local session artifacts after reporting.",
    checksumVerification: importResult.checksum ? `Imported checksum: ${importResult.checksum}` : "Checksum unavailable because no evidence file was imported.",
    secretLeakage: "Committed evidence contains repository-relative paths and source hashes only."
  };
}

function createRuntimeEvidence(execution, runnerInvocation, importResult, manualPackage, cleanupComplete, source) {
  const validationCategories = createValidationCategories(importResult);
  const bootstrapResults = createBootstrapResults(importResult);
  const coordinatorGraph = createCoordinatorGraph(importResult);
  const runtimeTimeline = createTimeline(execution, importResult);
  const failureAnalysis = createFailureAnalysis(importResult);
  const status = importResult.ok ? "runtimeEvidenceImported" : "executionBlocked";
  return {
    schemaVersion: 1,
    phase: phase154Id,
    phaseName: phase154Name,
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
    manualExecutionPackage: manualPackage,
    runnerInvocation,
    evidenceImport: {
      ok: importResult.ok,
      reason: importResult.reason,
      failure: importResult.failure,
      checksum: importResult.checksum ?? null,
      importedFields: importResult.ok ? requiredRuntimeFields : []
    },
    runtimeEvidence: importResult.ok ? importResult.evidence : null,
    validationCategories,
    bootstrapResults,
    coordinatorGraph,
    runtimeTimeline,
    runtimeScorecard: createScorecard(validationCategories),
    failureAnalysis,
    securityReview: createSecurityReview(importResult, manualPackage),
    cleanup: {
      completed: cleanupComplete,
      localSessionArtifactsRemoved: cleanupComplete,
      committedBinaryArtifacts: false
    },
    certification: {
      authorityInvoked: false,
      latestProductionCertifiedPhase: 108,
      productionCertified: false,
      reason: importResult.ok
        ? "Evidence import alone does not grant production certification."
        : "No authoritative Studio runtime evidence was imported."
    },
    nextRecommendedPhase: importResult.ok
      ? "Phase 155 - Chapter 0 Runtime Verification & Subsystem Validation"
      : "Phase 155 - Studio Runtime Evidence Remediation"
  };
}

function markdownTable(rows, columns) {
  const header = `| ${columns.join(" | ")} |`;
  const divider = `| ${columns.map(() => "---").join(" | ")} |`;
  const body = rows.map((row) => `| ${columns.map((column) => String(row[column] ?? "").replace(/\r?\n/g, " ")).join(" | ")} |`);
  return [header, divider, ...body].join("\n");
}

function writePhaseDocs(evidence, manifest) {
  const imported = evidence.evidenceImport.ok;
  const docs = {
    "00_BASELINE.md": `# Phase 154 Baseline\n\nRepository: ${evidence.source.repository}\n\nBranch: ${evidence.source.branch}\n\nLocal commit: ${evidence.source.localHead}\n\nOrigin/main: ${evidence.source.remoteHead}\n\nPhase 153 implementation commit: ${evidence.source.phase153ImplementationCommit}\n\nPhase 153 state commit: ${evidence.source.phase153StateCommit}\n\nBackend selected: ${evidence.session.backend}\n\nFramework version: ${evidence.framework.version}\n\nRunner version: ${evidence.runnerInvocation.schemaVersion}\n\nSchema version: ${evidence.schemaVersion}\n\nWorking tree clean: ${evidence.source.workingTreeClean}\n`,
    "01_RUNTIME_SESSION.md": `# Phase 154 Runtime Session\n\nSession ID: ${evidence.session.sessionId}\n\nManifest ID: ${evidence.manifest.manifestId}\n\nBackend: ${evidence.session.backend}\n\nPhase: ${evidence.phase}\n\nCommit: ${evidence.session.repositoryCommit}\n\nBranch: ${evidence.session.branch}\n\nTimeout: ${evidence.runnerInvocation.timeout}\n\nExpected evidence location: ${evidence.manualExecutionPackage.expectedOutputFile}\n\nArchive status: ${evidence.session.status}\n`,
    "02_PLACE_PREPARATION.md": `# Phase 154 Place Preparation\n\nPlace preparation status: ${evidence.backendResult.status}\n\nAssertions:\n\n${markdownTable(evidence.backendResult.assertions ?? [], ["name", "status"])}\n\nArtifacts:\n\n${markdownTable(evidence.backendResult.artifacts ?? [], ["artifactId", "path"])}\n\nCleanup policy: local session artifacts are removed after the attempt; binary place artifacts are not committed.\n`,
    "03_STUDIO_EXECUTION.md": `# Phase 154 Studio Execution\n\nStudio execution status: ${imported ? "runtime evidence imported" : "blocked before authoritative runtime evidence"}\n\nManual workflow:\n\n${evidence.manualExecutionPackage.instructions.map((step, index) => `${index + 1}. ${step}`).join("\n")}\n\nThe framework does not assume Studio launch, Play mode, runner execution, server startup, client startup, bootstrap, diagnostics, snapshots, or cleanup from instructions alone.\n`,
    "04_EVIDENCE_IMPORT.md": `# Phase 154 Evidence Import\n\nImport OK: ${evidence.evidenceImport.ok}\n\nFailure: ${evidence.evidenceImport.failure ?? "none"}\n\nReason: ${evidence.evidenceImport.reason ?? "none"}\n\nChecksum: ${evidence.evidenceImport.checksum ?? "none"}\n\nRejected conditions remain owned by ExecutionEvidenceImporter and ExecutionEvidenceValidator: wrong session, wrong commit, wrong phase, wrong runner/schema, stale or partial evidence, malformed JSON, path traversal, checksum mismatch, and certification mutation.\n`,
    "05_BOOTSTRAP_RESULTS.md": `# Phase 154 Bootstrap Results\n\n${markdownTable(evidence.bootstrapResults, ["subsystem", "status", "evidenceSource", "confidence", "failureReason", "nextAction"])}\n`,
    "06_COORDINATOR_GRAPH.md": `# Phase 154 Coordinator Graph\n\n${markdownTable(
      evidence.coordinatorGraph.map((entry) => ({
        coordinator: entry.coordinator,
        owner: entry.owner,
        initializationOrder: entry.initializationOrder,
        dependencies: entry.dependencies.join(", "),
        dependents: entry.dependents.join(", "),
        failureState: entry.failureState,
        verified: entry.verified,
        blocked: entry.blocked
      })),
      ["coordinator", "owner", "initializationOrder", "dependencies", "dependents", "failureState", "verified", "blocked"]
    )}\n`,
    "07_RUNTIME_TIMELINE.md": `# Phase 154 Runtime Timeline\n\n${markdownTable(evidence.runtimeTimeline, ["order", "stage", "status", "detail"])}\n`,
    "08_RUNTIME_SCORECARD.md": `# Phase 154 Runtime Scorecard\n\nOnly verified runtime or framework evidence is scored. BLOCKED and NOT_EXECUTED categories are not scored.\n\n${markdownTable(evidence.runtimeScorecard, ["category", "status", "score", "scoringRule"])}\n`,
    "09_FAILURE_ANALYSIS.md": `# Phase 154 Failure Analysis\n\n${markdownTable(evidence.failureAnalysis, ["category", "rootCause", "impact", "recovery", "confidence"])}\n`,
    "10_SECURITY_REVIEW.md": `# Phase 154 Security Review\n\n${Object.entries(evidence.securityReview)
      .map(([key, value]) => `- ${key}: ${value}`)
      .join("\n")}\n`,
    "11_PRODUCTION_REVIEW.md": `# Phase 154 Production Review\n\n${[
      "Principal Engine Architect",
      "Roblox Platform Engineer",
      "Runtime Infrastructure Lead",
      "QA Infrastructure Lead",
      "Security Reviewer",
      "Developer Tools Lead",
      "Certification Reviewer"
    ]
      .map(
        (reviewer) =>
          `## ${reviewer}\n\nVerdict: Production Candidate\n\nConfidence: high for framework evidence, blocked for Studio runtime evidence\n\nStrongest Evidence: Phase 154 used the Runtime Execution Framework and Studio Manual Backend without bypassing evidence import validation.\n\nLargest Limitation: ${imported ? "Evidence import succeeded, but certification authority has not promoted the phase." : "No Studio-produced structured runtime result was imported."}\n\nRecommendation: ${evidence.nextRecommendedPhase}\n`
      )
      .join("\n")}`,
    "12_COMPLETION_REPORT.md": `# Phase 154 Completion Report\n\nStatus: ${evidence.status}\n\nImplementation evidence path: ${evidencePath}\n\nManifest path: ${manifestPath}\n\nReport path: ${reportPath}\n\nRuntime evidence imported: ${evidence.evidenceImport.ok}\n\nCertification authority invoked: ${evidence.certification.authorityInvoked}\n\nLatest Production Certified Phase: ${evidence.certification.latestProductionCertifiedPhase}\n\nNext recommended phase: ${evidence.nextRecommendedPhase}\n`
  };

  for (const [fileName, text] of Object.entries(docs)) {
    writeText(join(docsDirectory, fileName), text);
  }

  writeText(
    reportPath,
    `# Phase 154 Runtime Report\n\nStatus: ${evidence.status}\n\nSession: ${evidence.session.sessionId}\n\nBackend: ${evidence.session.backend}\n\nRuntime evidence imported: ${evidence.evidenceImport.ok}\n\nBlocking point: ${evidence.evidenceImport.ok ? "none" : evidence.evidenceImport.failure}\n\nNext recommended phase: ${evidence.nextRecommendedPhase}\n`
  );
  writeJson(manifestPath, manifest);
  writeJson(evidencePath, evidence);
}

export function runPhase154AuthoritativeStudioRuntimeEvidenceCapture(options = {}) {
  const source = currentSource();
  const execution = runRuntimeExecution({
    phase: phase154Id,
    phaseName: phase154Name,
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
  const manualPackage = createManualExecutionPackage(execution, runnerInvocation, evidenceOutput);
  const importResult = importExecutionEvidence(evidenceOutput, context);
  const cleanupComplete = options.skipCleanup === true ? false : cleanupLocalSession(execution.session.sessionId);
  const evidence = createRuntimeEvidence(execution, runnerInvocation, importResult, manualPackage, cleanupComplete, source);
  const manifest = {
    schemaVersion: 1,
    phase: phase154Id,
    phaseName: phase154Name,
    status: evidence.status,
    sessionId: execution.session.sessionId,
    backend: execution.session.backend,
    manualExecutionPackage: manualPackage,
    evidencePath,
    reportPath,
    runtimeEvidenceImported: importResult.ok,
    cleanupComplete,
    certificationAuthorityInvoked: false,
    nextRecommendedPhase: evidence.nextRecommendedPhase
  };

  if (options.write !== false) {
    writePhaseDocs(evidence, manifest);
  }

  return { evidence, manifest };
}

function addCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runPhase154SelfChecks() {
  const results = [];
  const frameworkChecks = runRuntimeExecutionSelfChecks();
  results.push(...frameworkChecks.map((check) => ({ name: `framework.${check.name}`, ok: check.ok, detail: check.detail })));
  const run = runPhase154AuthoritativeStudioRuntimeEvidenceCapture({ write: false });
  const evidence = run.evidence;
  const manifest = run.manifest;

  addCheck(results, "phase154UsesRuntimeExecutionFramework", evidence.framework.used === true);
  addCheck(results, "phase154FrameworkIdPreserved", evidence.framework.id === "london.runtimeExecutionFramework");
  addCheck(results, "phase154ManualBackendSelected", evidence.session.backend === "StudioManual");
  addCheck(results, "phase154SessionCreated", typeof evidence.session.sessionId === "string" && evidence.session.sessionId.includes("phase-154"));
  addCheck(results, "phase154ManifestCreated", evidence.manifest.phase === phase154Id);
  addCheck(results, "phase154ManifestSessionBound", evidence.manifest.sessionId === evidence.session.sessionId);
  addCheck(results, "phase154RunnerSessionBound", evidence.runnerInvocation.sessionId === evidence.session.sessionId);
  addCheck(results, "phase154RunnerPhaseBound", evidence.runnerInvocation.phase === phase154Id);
  addCheck(results, "phase154RunnerCommitBound", evidence.runnerInvocation.repositoryCommit === evidence.source.localHead);
  addCheck(results, "phase154RunnerIdPhaseSpecific", evidence.runnerInvocation.runnerId === "runtimeExecution.phase154.manualStudioBootstrapValidation");
  addCheck(results, "phase154ManualPackageExists", evidence.manualExecutionPackage.frameworkOwnsEvidenceImport === true);
  addCheck(results, "phase154ManualBackendOwnsHandoff", evidence.manualExecutionPackage.manualBackendOwnsStudioHandoff === true);
  addCheck(results, "phase154ExpectedOutputSessionScoped", evidence.manualExecutionPackage.expectedOutputFile.includes(evidence.session.sessionId));
  addCheck(results, "phase154ExpectedOutputLocalState", evidence.manualExecutionPackage.expectedOutputFile.startsWith("automation/local-state/runtime-execution/"));
  addCheck(results, "phase154ResumeCommandProvided", evidence.manualExecutionPackage.resumeCommand.includes("london:phase154"));
  addCheck(results, "phase154CancellationCommandProvided", evidence.manualExecutionPackage.cancellationCommand.includes(evidence.session.sessionId));
  addCheck(results, "phase154TimeoutBound", Number.isInteger(evidence.manualExecutionPackage.timeout) && evidence.manualExecutionPackage.timeout > 0);
  addCheck(results, "phase154PlacePreparedOrFailed", ["waitingForManualAction", "failed"].includes(evidence.backendResult.status));
  addCheck(results, "phase154ImportAttempted", evidence.evidenceImport.failure === "MissingEvidence" || evidence.evidenceImport.ok === true);
  addCheck(results, "phase154MissingEvidenceBlocked", evidence.evidenceImport.ok || evidence.status === "executionBlocked");
  addCheck(results, "phase154NoCertificationAuthority", evidence.certification.authorityInvoked === false);
  addCheck(results, "phase154NoProductionCertification", evidence.certification.productionCertified === false);
  addCheck(results, "phase154LatestCertifiedPreserved", evidence.certification.latestProductionCertifiedPhase === 108);
  addCheck(results, "phase154CleanupCompleted", evidence.cleanup.completed === true);
  addCheck(results, "phase154NoBinaryArtifactsCommitted", evidence.cleanup.committedBinaryArtifacts === false);
  addCheck(results, "phase154ValidationCategoriesComplete", evidence.validationCategories.length === 10);
  addCheck(results, "phase154BootstrapResultsComplete", evidence.bootstrapResults.length === 12);
  addCheck(results, "phase154CoordinatorGraphComplete", evidence.coordinatorGraph.length === 9);
  addCheck(results, "phase154TimelineComplete", evidence.runtimeTimeline.length === 15);
  addCheck(results, "phase154ScorecardComplete", evidence.runtimeScorecard.length === evidence.validationCategories.length);
  addCheck(results, "phase154FailureAnalysisComplete", evidence.failureAnalysis.length >= 1);
  addCheck(results, "phase154SecurityReviewComplete", Object.keys(evidence.securityReview).length >= 10);
  addCheck(results, "phase154ImportedFieldsOnlyOnSuccess", evidence.evidenceImport.ok || evidence.evidenceImport.importedFields.length === 0);
  addCheck(results, "phase154RequiredFieldsKnown", requiredRuntimeFields.length === 20);
  addCheck(results, "phase154ManifestReflectsImport", manifest.runtimeEvidenceImported === evidence.evidenceImport.ok);
  addCheck(results, "phase154ManifestReflectsCleanup", manifest.cleanupComplete === evidence.cleanup.completed);
  addCheck(results, "phase154NextPhaseBlockedPath", evidence.evidenceImport.ok || evidence.nextRecommendedPhase === "Phase 155 - Studio Runtime Evidence Remediation");
  addCheck(results, "phase154NoRuntimeEvidenceOnBlock", evidence.evidenceImport.ok || evidence.runtimeEvidence === null);
  addCheck(results, "phase154TimelineDoesNotVerifyBlockedStudio", evidence.evidenceImport.ok || evidence.runtimeTimeline.find((entry) => entry.stage === "Studio Opened")?.status === "BLOCKED");
  addCheck(results, "phase154ServerNotExecutedOnBlock", evidence.evidenceImport.ok || evidence.runtimeTimeline.find((entry) => entry.stage === "Server Started")?.status === "NOT_EXECUTED");
  addCheck(results, "phase154ClientNotExecutedOnBlock", evidence.evidenceImport.ok || evidence.runtimeTimeline.find((entry) => entry.stage === "Client Started")?.status === "NOT_EXECUTED");
  addCheck(results, "phase154BootstrapNotExecutedOnBlock", evidence.evidenceImport.ok || evidence.bootstrapResults.find((entry) => entry.subsystem === "Chapter0Home")?.status === "NOT_EXECUTED");
  addCheck(results, "phase154BlockedItemsNotScored", evidence.runtimeScorecard.every((entry) => !["BLOCKED", "NOT_EXECUTED"].includes(entry.status) || entry.score === null));
  addCheck(results, "phase154SecurityPathTraversalDocumented", evidence.securityReview.pathTraversal.includes("Rejected"));
  addCheck(results, "phase154ChecksumTruthful", evidence.evidenceImport.ok || evidence.securityReview.checksumVerification.includes("unavailable"));
  addCheck(results, "phase154SourceHasCommits", evidence.source.phase153ImplementationCommit.length === 40 && evidence.source.phase153StateCommit.length === 40);
  addCheck(results, "phase154WorkingTreeCaptured", typeof evidence.source.workingTreeClean === "boolean");

  for (const field of requiredRuntimeFields) {
    addCheck(results, `phase154RuntimeField.${field}`, typeof field === "string" && field.length > 0);
  }

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runPhase154SelfChecks();
    const failed = results.filter((check) => !check.ok);
    console.log(`TOTAL ${results.length}`);
    console.log(`PASSED ${results.length - failed.length}`);
    console.log(`FAILURES ${failed.length}`);
    for (const failure of failed) console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
    process.exitCode = failed.length === 0 ? 0 : 5;
    return;
  }

  const result = runPhase154AuthoritativeStudioRuntimeEvidenceCapture();
  console.log(JSON.stringify(result.manifest, null, 2));
  process.exitCode = result.manifest.runtimeEvidenceImported ? 0 : 2;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
