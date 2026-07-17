import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { git, readJson, runCommand } from "./repository-state.mjs";

const cwd = process.cwd();
const config = readJson("automation/config/automation-config.json");
const args = new Set(process.argv.slice(2));

const phase = 120;
const runnerId = "chapter0Home.phase118ObservationCertification";
const runnerPath = "ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner";
const contractPath = "ServerScriptService.Chapter0Home.Studio.Phase118CertificationContract";
const studioGate = "LondonPhase118RunCertification";
const evidenceJsonPath = "automation/local-state/phase120-certification-evidence.json";
const evidenceMarkdownPath = "automation/local-state/phase120-certification-evidence.md";
const sourceCommitPattern = /^[a-f0-9]{40}$/;

const exitCodes = {
  success: 0,
  runtimeUnavailable: 1,
  executionBlocked: 2,
  validationFailed: 3,
  runnerFailed: 4,
  cleanupFailed: 5,
  upstreamFailed: 6,
  sourceAttributionInvalid: 7
};

function normalize(path) {
  return path.replaceAll("\\", "/");
}

function timestamp() {
  return new Date().toISOString();
}

function commandExists(command) {
  const probe =
    process.platform === "win32"
      ? runCommand("where", [command], { cwd })
      : runCommand("command", ["-v", command], { cwd, shell: true });
  return probe.ok ? probe.stdout.split(/\r?\n/).find(Boolean)?.trim() ?? command : null;
}

function existingPath(paths) {
  for (const path of paths) {
    if (existsSync(path)) {
      return path;
    }
  }

  return null;
}

function studioCandidatePaths() {
  const localAppData = process.env.LOCALAPPDATA;
  const candidates = [
    ...(config.studioCertification?.studioExecutablePaths ?? []),
    "RobloxStudioBeta",
    "RobloxStudioLauncherBeta"
  ];

  if (localAppData) {
    candidates.push(join(localAppData, "Roblox", "Versions", "version-ed7d8193e8564b1f", "RobloxStudioBeta.exe"));
  }

  return candidates;
}

function detectStudio() {
  const configured = existingPath(
    (config.studioCertification?.studioExecutablePaths ?? []).filter((path) => path.includes("\\") || path.includes("/"))
  );

  if (configured !== null) {
    return { available: true, executable: configured, detection: "configuredPath" };
  }

  const fromPath = commandExists(config.studioCertification?.studioExecutableName ?? "RobloxStudioBeta");
  if (fromPath !== null) {
    return { available: true, executable: fromPath, detection: "PATH" };
  }

  const launcher = commandExists("RobloxStudioLauncherBeta");
  if (launcher !== null) {
    return { available: true, executable: launcher, detection: "PATH" };
  }

  const localInstall = existingPath(studioCandidatePaths());
  if (localInstall !== null) {
    return { available: true, executable: localInstall, detection: "localInstall" };
  }

  return { available: false, executable: null, detection: "notFound" };
}

function inspectSource() {
  const branch = git(config, ["branch", "--show-current"], { cwd });
  const localHead = git(config, ["rev-parse", "HEAD"], { cwd });
  const remoteHead = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`], { cwd });
  const lsRemote = git(config, ["ls-remote", "origin", `refs/heads/${config.branch ?? "main"}`], { cwd });
  const status = git(config, ["status", "--short", "--branch"], { cwd });
  const workingTreeClean =
    status.ok &&
    status.stdout
      .split(/\r?\n/)
      .filter((line) => line.trim() && !line.startsWith("##")).length === 0;
  const remoteAdvertisedHead = lsRemote.stdout.split(/\s+/)[0] ?? "";
  const exactSourceCommit = localHead.stdout.trim();
  const originMain = remoteAdvertisedHead || remoteHead.stdout.trim();
  const valid =
    branch.ok &&
    branch.stdout.trim() === (config.branch ?? "main") &&
    sourceCommitPattern.test(exactSourceCommit) &&
    sourceCommitPattern.test(originMain) &&
    exactSourceCommit === originMain &&
    workingTreeClean;

  return {
    valid,
    branch: branch.stdout.trim(),
    exactSourceCommit,
    currentHead: exactSourceCommit,
    originMain,
    workingTreeClean,
    commandResults: {
      branch,
      localHead,
      remoteHead,
      lsRemote,
      status
    }
  };
}

function evidenceId(captureTimestamp) {
  return `${runnerId}.${captureTimestamp.replace(/[^A-Za-z0-9]/g, "-")}`;
}

function blockedEvidence(source, studio, status, nextAction, warning) {
  const captureTimestamp = timestamp();
  return {
    schemaVersion: 1,
    phase,
    runnerId,
    runnerPath,
    contractPath,
    runtime: "RobloxStudio",
    studio: {
      available: studio.available,
      executable: studio.executable,
      detection: studio.detection,
      supportedNonInteractiveCapture: false
    },
    status,
    setupStatus: status === "runtimeUnavailable" ? "runtimeUnavailable" : "executionBlocked",
    assertionStatus: "notExecuted",
    cleanupStatus: "notExecuted",
    upstreamStatus: "notExecuted",
    executedSuites: [],
    skippedSuites: [
      "Chapter0Home",
      "Chapter0Home.ObservationIntegration",
      "Chapter0Home.Phase117Hardening",
      "Upstream.PlayerExperience",
      "Upstream.InteractionRuntime",
      "Upstream.ObservationEngine",
      "RemoteContract.PlayerExperience",
      "EventBus.PublicationBoundary",
      "Chapter0Home.ResetCleanup",
      "Chapter0Home.DiagnosticsSnapshots"
    ],
    totals: {
      total: "notExecuted",
      passed: "notExecuted",
      failed: "notExecuted"
    },
    failures: [],
    warnings: warning ? [warning] : [],
    productionCertified: false,
    evidenceId: evidenceId(captureTimestamp),
    exactSourceCommit: source.exactSourceCommit,
    currentHead: source.currentHead,
    originMain: source.originMain,
    workingTreeClean: source.workingTreeClean,
    captureTimestamp,
    validationStatus: source.valid ? "notExecuted" : "sourceAttributionInvalid",
    decisionStatus: "notCertified",
    nextAction
  };
}

function validateEvidenceEnvelope(evidence) {
  const required = [
    "schemaVersion",
    "phase",
    "runnerId",
    "runtime",
    "studio",
    "status",
    "setupStatus",
    "assertionStatus",
    "cleanupStatus",
    "upstreamStatus",
    "executedSuites",
    "skippedSuites",
    "totals",
    "failures",
    "warnings",
    "productionCertified",
    "evidenceId",
    "exactSourceCommit",
    "captureTimestamp",
    "validationStatus",
    "decisionStatus",
    "nextAction"
  ];

  for (const field of required) {
    if (!(field in evidence)) {
      return { ok: false, reason: `missing ${field}` };
    }
  }

  if (evidence.schemaVersion !== 1 || evidence.phase !== phase || evidence.runnerId !== runnerId) {
    return { ok: false, reason: "identity mismatch" };
  }

  if (!sourceCommitPattern.test(evidence.exactSourceCommit)) {
    return { ok: false, reason: "invalid exactSourceCommit" };
  }

  if (!Array.isArray(evidence.executedSuites) || !Array.isArray(evidence.skippedSuites)) {
    return { ok: false, reason: "suite fields must be arrays" };
  }

  if (
    typeof evidence.totals !== "object" ||
    evidence.totals === null ||
    !("total" in evidence.totals) ||
    !("passed" in evidence.totals) ||
    !("failed" in evidence.totals)
  ) {
    return { ok: false, reason: "invalid totals" };
  }

  if (evidence.productionCertified === true && evidence.status !== "passed") {
    return { ok: false, reason: "certified evidence must be passed" };
  }

  return { ok: true, reason: null };
}

function writeEvidence(evidence) {
  mkdirSync(dirname(evidenceJsonPath), { recursive: true });
  writeFileSync(evidenceJsonPath, `${JSON.stringify(evidence, null, 2)}\n`);
  writeFileSync(evidenceMarkdownPath, markdownEvidence(evidence));
}

function markdownEvidence(evidence) {
  return `# Phase 120 Studio Certification Evidence

Status: ${evidence.status}

Runtime availability: ${evidence.studio.available ? "Roblox Studio detected" : "Runtime unavailable"}

Studio execution: ${evidence.studio.supportedNonInteractiveCapture ? "supported" : "execution blocked"}

Executed suites: ${evidence.executedSuites.length}

Skipped suites: ${evidence.skippedSuites.length}

Totals: ${JSON.stringify(evidence.totals)}

Validation: ${evidence.validationStatus}

Decision: ${evidence.decisionStatus}

Cleanup: ${evidence.cleanupStatus}

Source attribution:

- exactSourceCommit: ${evidence.exactSourceCommit}
- currentHead: ${evidence.currentHead}
- originMain: ${evidence.originMain}
- workingTreeClean: ${evidence.workingTreeClean}

Evidence ID: ${evidence.evidenceId}

Next action: ${evidence.nextAction}
`;
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

function runSelfChecks() {
  const results = [];
  const source = {
    valid: true,
    exactSourceCommit: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    currentHead: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    originMain: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    workingTreeClean: true
  };
  const studio = { available: false, executable: null, detection: "notFound" };
  const evidence = blockedEvidence(
    source,
    studio,
    "runtimeUnavailable",
    "Install or expose a supported Roblox Studio automation capture path, then rerun certification.",
    "self-check"
  );
  const validation = validateEvidenceEnvelope(evidence);

  assertSelfCheck(results, "jsonSchema", validation.ok, validation.reason ?? "");
  assertSelfCheck(results, "markdownSchema", markdownEvidence(evidence).includes("Source attribution:"), "");
  assertSelfCheck(results, "sourceAttribution", evidence.exactSourceCommit === evidence.originMain, "");
  assertSelfCheck(results, "evidenceValidation", evidence.validationStatus === "notExecuted", "");
  assertSelfCheck(results, "decisionConsistency", evidence.productionCertified === false, "");
  assertSelfCheck(results, "machineReadableExport", JSON.parse(JSON.stringify(evidence)).phase === phase, "");
  assertSelfCheck(results, "artifactOverwriteSafety", evidenceJsonPath.includes("automation/local-state/"), "");
  assertSelfCheck(results, "staleArtifactRejection", validateEvidenceEnvelope({ ...evidence, phase: 119 }).ok === false, "");
  assertSelfCheck(results, "corruptedArtifactRejection", validateEvidenceEnvelope({ ...evidence, totals: null }).ok === false, "");
  assertSelfCheck(results, "wrapperExitCodes", exitCodes.executionBlocked === 2 && exitCodes.sourceAttributionInvalid === 7, "");
  assertSelfCheck(results, "wrapperArgumentValidation", args.has("--self-check"), "");
  assertSelfCheck(results, "cleanupVerification", evidence.cleanupStatus === "notExecuted", "");
  assertSelfCheck(results, "rerunSafety", evidence.evidenceId.startsWith(`${runnerId}.`), "");
  assertSelfCheck(results, "runtimeTruthfulness", evidence.status === "runtimeUnavailable", "");

  const failed = results.filter((result) => !result.ok);
  console.log(`TOTAL ${results.length}`);
  console.log(`PASSED ${results.length - failed.length}`);
  console.log(`FAILURES ${failed.length}`);
  for (const failure of failed) {
    console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
  }

  process.exitCode = failed.length === 0 ? 0 : 3;
}

function main() {
  if (args.has("--self-check")) {
    runSelfChecks();
    return;
  }

  if (args.has("--help")) {
    console.log("Usage: node automation/studio-certification-capture.mjs [--self-check]");
    console.log("Exit 0 success, 1 runtime unavailable, 2 execution blocked, 3 validation failed, 4 runner failed, 5 cleanup failed, 6 upstream failed, 7 source attribution invalid.");
    return;
  }

  const source = inspectSource();
  const studio = detectStudio();

  if (!source.valid) {
    const evidence = blockedEvidence(
      source,
      studio,
      "sourceAttributionInvalid",
      "Clean the working tree and verify local HEAD matches origin/main before certification.",
      "Source attribution failed; certification evidence was not executed."
    );
    writeEvidence(evidence);
    console.log("Source attribution invalid");
    console.log(`Evidence JSON: ${normalize(evidenceJsonPath)}`);
    console.log(`Evidence Markdown: ${normalize(evidenceMarkdownPath)}`);
    process.exitCode = exitCodes.sourceAttributionInvalid;
    return;
  }

  if (!studio.available) {
    const evidence = blockedEvidence(
      source,
      studio,
      "runtimeUnavailable",
      "Install Roblox Studio or configure a supported Studio executable path, then rerun certification.",
      "Roblox Studio was not detected."
    );
    writeEvidence(evidence);
    console.log("Runtime unavailable");
    console.log(`Evidence JSON: ${normalize(evidenceJsonPath)}`);
    console.log(`Evidence Markdown: ${normalize(evidenceMarkdownPath)}`);
    process.exitCode = exitCodes.runtimeUnavailable;
    return;
  }

  const evidence = blockedEvidence(
    source,
    studio,
    "executionBlocked",
    "Add a supported non-interactive Roblox Studio execution and structured-result capture workflow before claiming certification.",
    `Roblox Studio was detected at ${studio.executable}, but no supported non-interactive execution/capture API is configured for ${runnerPath}.`
  );
  const validation = validateEvidenceEnvelope(evidence);
  if (!validation.ok) {
    evidence.validationStatus = "validationFailed";
    evidence.warnings.push(`Evidence envelope validation failed: ${validation.reason}`);
    writeEvidence(evidence);
    console.log("Validation failed");
    console.log(validation.reason);
    process.exitCode = exitCodes.validationFailed;
    return;
  }

  writeEvidence(evidence);
  console.log("Execution blocked");
  console.log(`Runtime detected: Roblox Studio (${studio.detection})`);
  console.log(`Runner: ${runnerPath}`);
  console.log(`Contract: ${contractPath}`);
  console.log(`Gate: ${studioGate}`);
  console.log(`Evidence JSON: ${normalize(evidenceJsonPath)}`);
  console.log(`Evidence Markdown: ${normalize(evidenceMarkdownPath)}`);
  process.exitCode = exitCodes.executionBlocked;
}

main();
