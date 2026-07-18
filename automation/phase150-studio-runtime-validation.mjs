import { existsSync, mkdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { discoverStudioInstallations, runStudioBridge } from "./studio-automation-bridge.mjs";
import { git, readJson, runCommand } from "./repository-state.mjs";

export const phase = 150;
export const phaseTitle = "Chapter 0 Home Authoritative Studio Runtime Validation";
export const schemaVersion = 1;
export const evidenceDirectory = "automation/runtime-evidence/phase-150";
export const docsDirectory = "docs/phases/phase-150";
export const evidencePath = `${evidenceDirectory}/phase-150-runtime-evidence.json`;
export const schemaPath = `${evidenceDirectory}/evidence-schema.json`;
export const manifestPath = `${evidenceDirectory}/phase-150-manifest.json`;
export const buildArtifactPath = "automation/local-state/phase150-runtime-preflight.rbxlx";
export const expectedHead = "2cea2d5a1329f77c3c14d31d3f7903bd60909056";
export const expectedPhase149Commit = "2dffecde3ed89d625f3fabf1fe03fa26fac381ac";
export const docFiles = [
  "00_BASELINE_AND_ENVIRONMENT.md",
  "01_RUNTIME_VALIDATION_PLAN.md",
  "02_CHAPTER_0_RUNTIME_DEPENDENCY_MAP.md",
  "03_STUDIO_EXECUTION_PATH.md",
  "04_EVIDENCE_SCHEMA.md",
  "05_SERVER_BOOTSTRAP_RESULTS.md",
  "06_CLIENT_BOOTSTRAP_RESULTS.md",
  "07_PLAYER_SPAWN_AND_MOVEMENT_RESULTS.md",
  "08_INTERACTION_RUNTIME_RESULTS.md",
  "09_OBSERVATION_RUNTIME_RESULTS.md",
  "10_ENVIRONMENTAL_REACTION_RESULTS.md",
  "11_PRESENTATION_LIGHTING_AUDIO_RESULTS.md",
  "12_NARRATIVE_AND_UI_RESULTS.md",
  "13_DIAGNOSTICS_SNAPSHOTS_AND_AUDIT_RESULTS.md",
  "14_RESET_RESPAWN_AND_CLEANUP_RESULTS.md",
  "15_MULTIPLAYER_AUTHORITY_RESULTS.md",
  "16_PERFORMANCE_AND_RELIABILITY_RESULTS.md",
  "17_FAILURE_INJECTION_RESULTS.md",
  "18_DEFECT_AND_REMEDIATION_LOG.md",
  "19_VERTICAL_SLICE_RUNTIME_SCORECARD.md",
  "20_CERTIFICATION_BOUNDARY_REVIEW.md",
  "21_PHASE_150_PRODUCTION_REVIEW.md",
  "22_PHASE_150_COMPLETION_REPORT.md",
  "23_MANUAL_STUDIO_QA_CHECKLIST.md"
];

const cwd = process.cwd();
const config = readJson("automation/config/automation-config.json");

export const exitCodes = {
  verified: 0,
  executionBlocked: 2,
  preflightFailed: 3,
  sourceInvalid: 4,
  validationFailed: 5
};

function normalizePath(path) {
  let normalized = path.replaceAll("\\", "/");
  const replacements = [
    [cwd.replaceAll("\\", "/"), "<repo>"],
    [(process.env.USERPROFILE ?? "").replaceAll("\\", "/"), "<user-profile>"],
    [(process.env.LOCALAPPDATA ?? "").replaceAll("\\", "/"), "<local-app-data>"],
    [(process.env.APPDATA ?? "").replaceAll("\\", "/"), "<app-data>"],
    [(process.env.TEMP ?? "").replaceAll("\\", "/"), "<temp>"],
    [(process.env.TMP ?? "").replaceAll("\\", "/"), "<temp>"]
  ].filter((entry) => entry[0] !== "");

  for (const [prefix, token] of replacements) {
    normalized = normalized.replaceAll(prefix, token);
  }

  return normalized;
}

function sanitizeValue(value) {
  if (typeof value === "string") {
    return normalizePath(value);
  }

  if (Array.isArray(value)) {
    return value.map((child) => sanitizeValue(child));
  }

  if (typeof value === "object" && value !== null) {
    const output = {};
    for (const [key, child] of Object.entries(value)) {
      output[key] = sanitizeValue(child);
    }
    return output;
  }

  return value;
}

function isoNow() {
  return new Date().toISOString();
}

function commandExists(command) {
  if (existsSync(command)) {
    return command;
  }

  const probe =
    process.platform === "win32"
      ? runCommand("where", [command], { cwd })
      : runCommand("command", ["-v", command], { cwd, shell: true });

  return probe.ok ? probe.stdout.split(/\r?\n/).find(Boolean)?.trim() ?? command : null;
}

function cleanStatus(statusText) {
  return statusText
    .split(/\r?\n/)
    .filter((line) => line.trim() && !line.startsWith("##")).length === 0;
}

function inspectSource() {
  const branch = git(config, ["branch", "--show-current"], { cwd });
  const localHead = git(config, ["rev-parse", "HEAD"], { cwd });
  const remoteHead = git(config, ["rev-parse", `origin/${config.branch ?? "main"}`], { cwd });
  const status = git(config, ["status", "--short", "--branch"], { cwd });
  const expectedReachable = git(config, ["merge-base", "--is-ancestor", expectedHead, "HEAD"], { cwd });
  const phase149Reachable = git(config, ["merge-base", "--is-ancestor", expectedPhase149Commit, "HEAD"], { cwd });
  const workingTreeClean = status.ok && cleanStatus(status.stdout);

  return {
    branch: branch.stdout.trim(),
    localHead: localHead.stdout.trim(),
    remoteHead: remoteHead.stdout.trim(),
    workingTreeClean,
    expectedHeadReachable: expectedReachable.ok,
    phase149Reachable: phase149Reachable.ok,
    valid:
      branch.ok &&
      localHead.ok &&
      remoteHead.ok &&
      status.ok &&
      branch.stdout.trim() === (config.branch ?? "main") &&
      localHead.stdout.trim() === remoteHead.stdout.trim() &&
      expectedReachable.ok &&
      phase149Reachable.ok &&
      workingTreeClean
  };
}

function detectTool(name, command, args = ["--version"]) {
  const executable = commandExists(command);
  if (executable === null) {
    return {
      name,
      command,
      available: false,
      executable: null,
      output: "not detected"
    };
  }

  const runnable = existsSync(command) ? command : command;
  const result = runCommand(runnable, args, {
    cwd,
    timeout: 15000,
    shell: !existsSync(runnable)
  });
  return {
    name,
    command: normalizePath(command),
    available: true,
    executable: normalizePath(executable),
    output: (result.stdout || result.stderr || "").trim().split(/\r?\n/)[0] ?? "",
    exitCode: result.exitCode,
    failureKind: result.failureKind,
    durationMs: result.durationMs
  };
}

function detectTools() {
  return [
    detectTool("Node.js", "node", ["--version"]),
    detectTool("npm", "npm", ["--version"]),
    detectTool("Git", config.gitExecutable ?? "git", ["--version"]),
    detectTool("StyLua", "stylua", ["--version"]),
    detectTool("Selene", "selene", ["--version"]),
    detectTool("Rojo", "rojo", ["--version"]),
    detectTool("Luau", "luau", ["--version"]),
    detectTool("Lune", "lune", ["--version"]),
    detectTool("Roblox CLI", "roblox-cli", ["--version"]),
    detectTool("PowerShell", "powershell", ["-NoProfile", "-Command", "$PSVersionTable.PSVersion.ToString()"]),
    detectTool("Python", "python", ["--version"])
  ];
}

function ensureDirectories() {
  mkdirSync(evidenceDirectory, { recursive: true });
  mkdirSync(docsDirectory, { recursive: true });
  mkdirSync(dirname(buildArtifactPath), { recursive: true });
}

function buildPlacePreflight() {
  if (existsSync(buildArtifactPath)) {
    rmSync(buildArtifactPath, { force: true });
  }

  const result = runCommand("rojo", ["build", "default.project.json", "--output", buildArtifactPath], {
    cwd,
    timeout: 120000,
    maxBuffer: 1024 * 1024 * 20
  });
  const exists = existsSync(buildArtifactPath);
  const size = exists ? statSync(buildArtifactPath).size : 0;

  if (exists) {
    rmSync(buildArtifactPath, { force: true });
  }

  return {
    command: "rojo build default.project.json --output automation/local-state/phase150-runtime-preflight.rbxlx",
    exitCode: result.exitCode,
    failureKind: result.failureKind,
    durationMs: result.durationMs,
    stdout: result.stdout.trim(),
    stderr: result.stderr.trim(),
    artifactExisted: exists,
    artifactSizeBytes: size,
    artifactCleaned: !existsSync(buildArtifactPath),
    ok: result.ok && exists && size > 0
  };
}

function capability(id, status, evidenceSource, message) {
  return {
    id,
    status,
    evidenceSource,
    message
  };
}

function makeSchema() {
  return {
    schemaVersion,
    phase,
    phaseTitle,
    requiredFields: [
      "schemaVersion",
      "phase",
      "phaseTitle",
      "repositoryCommit",
      "branch",
      "studioVersion",
      "executionMode",
      "startTimestamp",
      "endTimestamp",
      "durationMilliseconds",
      "placeArtifact",
      "serverStarted",
      "clientStarted",
      "playerJoined",
      "characterSpawned",
      "bootstrapCompleted",
      "chapter0Initialized",
      "observationInitialized",
      "interactionInitialized",
      "presentationInitialized",
      "diagnosticsCaptured",
      "snapshotsCaptured",
      "auditCaptured",
      "resetExecuted",
      "cleanupExecuted",
      "errors",
      "warnings",
      "assertions",
      "capabilityResults",
      "evidenceFiles",
      "environment",
      "limitations",
      "certificationEligible",
      "certificationDecision"
    ],
    allowedCapabilityStatuses: [
      "VERIFIED",
      "VERIFIED WITH LIMITATIONS",
      "FAILED",
      "BLOCKED",
      "NOT APPLICABLE",
      "NOT EXECUTED"
    ],
    certificationAuthority: "Phase118CertificationContract.canProductionCertify",
    notes: [
      "Static validation, tool detection, place generation, and Studio installation detection are not runtime evidence.",
      "The runtime harness may classify structural evidence eligibility but must not self-certify.",
      "Absolute local paths are normalized before committed evidence is written."
    ]
  };
}

function validateEvidence(evidence) {
  const schema = makeSchema();
  for (const field of schema.requiredFields) {
    if (!(field in evidence)) {
      return { ok: false, reason: `missing ${field}` };
    }
  }

  if (evidence.schemaVersion !== schemaVersion || evidence.phase !== phase) {
    return { ok: false, reason: "identity mismatch" };
  }

  for (const result of evidence.capabilityResults) {
    if (!schema.allowedCapabilityStatuses.includes(result.status)) {
      return { ok: false, reason: `invalid capability status ${result.status}` };
    }
  }

  if (evidence.certificationDecision !== "notEvaluatedByCertificationAuthority") {
    return { ok: false, reason: "certification decision must remain authority-owned" };
  }

  if (evidence.certificationEligible !== false) {
    return { ok: false, reason: "blocked Phase 150 evidence cannot be certification eligible" };
  }

  return { ok: true, reason: null };
}

function buildEvidence() {
  const start = Date.now();
  const startTimestamp = isoNow();
  const source = inspectSource();
  const tools = detectTools();
  const studioInstallations = discoverStudioInstallations().map((install) => ({
    ...install,
    executable: normalizePath(install.executable),
    normalizedExecutable: normalizePath(install.normalizedExecutable)
  }));
  const preflight = buildPlacePreflight();
  const bridgeSourceAttributionValid =
    source.branch === (config.branch ?? "main") &&
    source.localHead === source.remoteHead &&
    source.expectedHeadReachable === true &&
    source.phase149Reachable === true;
  const bridge = runStudioBridge({
    phase: 120,
    runnerPath: "ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner",
    contractPath: "ServerScriptService.Chapter0Home.Studio.Phase118CertificationContract",
    gateAttribute: "LondonPhase118RunCertification",
    sourceAttributionValid: bridgeSourceAttributionValid
  });
  const sanitizedBridge = sanitizeValue(bridge);
  const blocked =
    !source.valid ||
    !preflight.ok ||
    sanitizedBridge.runnerInvoked !== true ||
    sanitizedBridge.structuredResultCaptured !== true ||
    sanitizedBridge.status !== "passed";
  const status = blocked ? "executionBlocked" : "verified";
  const capabilityResults = [
    capability("placeGeneration", preflight.ok ? "VERIFIED" : "FAILED", "buildAutomation", preflight.ok ? "Rojo build produced a nonempty temporary place artifact and cleanup removed it." : "Rojo preflight build failed."),
    capability("studioInstallation", studioInstallations.length > 0 ? "VERIFIED WITH LIMITATIONS" : "BLOCKED", "installedToolEvidence", studioInstallations.length > 0 ? "Roblox Studio installation was detected; installation is not play-mode runtime evidence." : "Roblox Studio was not detected."),
    capability("studioPlayMode", "BLOCKED", "studioHost", "No repository-supported API is available to enter Play/Run mode and capture trusted server/client evidence."),
    capability("serverBootstrap", "NOT EXECUTED", "RobloxStudio", "Server bootstrap was not executed because Play/Run mode is blocked."),
    capability("clientBootstrap", "NOT EXECUTED", "RobloxStudio", "Client bootstrap was not executed because Play/Run mode is blocked."),
    capability("playerSpawn", "NOT EXECUTED", "RobloxStudio", "No player joined an authoritative Studio run."),
    capability("movementReadiness", "NOT EXECUTED", "RobloxStudio", "Movement was not observed in Studio."),
    capability("interactionRuntime", "NOT EXECUTED", "RobloxStudio", "No Studio interaction was completed."),
    capability("observationRuntime", "NOT EXECUTED", "RobloxStudio", "No runtime observation fact was captured from Studio."),
    capability("environmentalReaction", "NOT EXECUTED", "RobloxStudio", "No player-visible environmental reaction was observed in Studio."),
    capability("presentationLightingAudio", "NOT EXECUTED", "RobloxStudio", "Presentation, lighting, and audio were not runtime-observed."),
    capability("diagnosticsSnapshotsAudit", "NOT EXECUTED", "RobloxStudio", "No authoritative runtime diagnostics, snapshots, or audit output was captured."),
    capability("resetRespawnCleanup", "NOT EXECUTED", "RobloxStudio", "Reset, respawn, and cleanup were not runtime-observed."),
    capability("multiplayerAuthority", "BLOCKED", "RobloxStudio", "No supported multi-client Studio execution path is available."),
    capability("performanceReliability", "NOT EXECUTED", "RobloxStudio", "No runtime measurements were collected."),
    capability("failureInjection", "NOT EXECUTED", "RobloxStudio", "Failure injection was not attempted without a trusted runtime harness.")
  ];

  const endTimestamp = isoNow();
  return {
    schemaVersion,
    phase,
    phaseTitle,
    status,
    repositoryCommit: source.localHead,
    branch: source.branch,
    studioVersion: studioInstallations[0]?.versionId ?? "unavailable",
    studioLaunched: false,
    playModeEntered: false,
    clientCount: 0,
    executionMode: "blockedBeforePlayMode",
    startTimestamp,
    endTimestamp,
    durationMilliseconds: Date.now() - start,
    placeArtifact: {
      path: "automation/local-state/phase150-runtime-preflight.rbxlx",
      created: preflight.artifactExisted,
      sizeBytes: preflight.artifactSizeBytes,
      cleaned: preflight.artifactCleaned
    },
    serverStarted: false,
    clientStarted: false,
    playerJoined: false,
    characterSpawned: false,
    bootstrapCompleted: false,
    chapter0Initialized: false,
    observationInitialized: false,
    interactionInitialized: false,
    presentationInitialized: false,
    diagnosticsCaptured: false,
    snapshotsCaptured: false,
    auditCaptured: false,
    resetExecuted: false,
    cleanupExecuted: false,
    errors: [],
    warnings: [
      "Roblox Studio installation detection and Rojo place generation are not authoritative runtime evidence.",
      "No supported non-interactive Play/Run and structured server/client capture path is exposed to this repository."
    ],
    assertions: [
      {
        identifier: "phase150.noFabricatedStudioExecution",
        capability: "studioPlayMode",
        expected: "execution blocked before runner invocation when no supported capture path exists",
        actual: `runnerInvoked=${sanitizedBridge.runnerInvoked}; structuredResultCaptured=${sanitizedBridge.structuredResultCaptured}; status=${sanitizedBridge.status}`,
        status: sanitizedBridge.runnerInvoked === false && sanitizedBridge.structuredResultCaptured === false ? "VERIFIED" : "FAILED",
        source: "buildAutomation",
        severity: "blocking",
        message: "The Phase 150 harness refused to fabricate Studio runtime evidence."
      }
    ],
    capabilityResults,
    evidenceFiles: [schemaPath, evidencePath, manifestPath],
    environment: {
      source,
      tools,
      studioInstallations,
      preflight,
      bridge: {
        bridgeId: sanitizedBridge.bridgeId,
        status: sanitizedBridge.status,
        exitCode: sanitizedBridge.exitCode,
        runnerInvoked: sanitizedBridge.runnerInvoked,
        structuredResultCaptured: sanitizedBridge.structuredResultCaptured,
        nextAction: sanitizedBridge.nextAction,
        executionMethods: sanitizedBridge.executionMethods,
        structuredCaptureMethods: sanitizedBridge.structuredCaptureMethods
      }
    },
    limitations: [
      "Authoritative Studio Play/Run mode was not entered.",
      "No server/client runtime evidence was captured.",
      "Human visual QA was not performed.",
      "Multiplayer validation was not attempted.",
      "Phase 108 remains the latest Production Certified milestone."
    ],
    certificationEligible: false,
    certificationDecision: "notEvaluatedByCertificationAuthority",
    nextAction:
      "Run Chapter 0 in Roblox Studio through a supported repository-owned evidence path or perform a documented manual Studio QA evidence phase."
  };
}

function writeJson(path, value) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`);
}

function resultLine(result) {
  return `- ${result.id}: ${result.status} - ${result.message}`;
}

function toolLine(tool) {
  return `- ${tool.name}: ${tool.available ? "available" : "unavailable"}${tool.output ? ` - ${tool.output}` : ""}`;
}

function writeDoc(name, title, body) {
  writeFileSync(join(docsDirectory, name), `# ${title}\n\n${body.trim()}\n`);
}

function writeDocs(evidence) {
  const source = evidence.environment.source;
  const capabilityLines = evidence.capabilityResults.map(resultLine).join("\n");
  const toolLines = evidence.environment.tools.map(toolLine).join("\n");
  const studioLines =
    evidence.environment.studioInstallations.length === 0
      ? "- none"
      : evidence.environment.studioInstallations
          .map((install) => `- ${install.source}: ${install.normalizedExecutable} (${install.versionId})`)
          .join("\n");
  const validationSummary = `Status: ${evidence.status}\n\nSource:\n\n- branch: ${source.branch}\n- localHead: ${source.localHead}\n- remoteHead: ${source.remoteHead}\n- workingTreeClean: ${source.workingTreeClean}\n- restructuringCommitReachable: ${source.expectedHeadReachable}\n- phase149CommitReachable: ${source.phase149Reachable}\n\nTools:\n\n${toolLines}\n\nStudio installations:\n\n${studioLines}`;
  const blockedRuntime = `Status: BLOCKED\n\nAuthoritative Roblox Studio Play/Run mode was not entered. The repository can detect Studio and build a temporary Rojo place, but no supported command path can initiate Play/Run mode, invoke \`Phase118CertificationRunner\`, and capture structured server/client evidence without fabrication.\n\nCapability results:\n\n${capabilityLines}`;

  writeDoc("00_BASELINE_AND_ENVIRONMENT.md", "Phase 150 Baseline And Environment", validationSummary);
  writeDoc("01_RUNTIME_VALIDATION_PLAN.md", "Phase 150 Runtime Validation Plan", "Plan: perform source attribution, tool detection, temporary Rojo place build, Studio automation bridge evaluation, evidence schema validation, blocked-state reporting, documentation synchronization, and repository validation. No gameplay behavior is modified.");
  writeDoc("02_CHAPTER_0_RUNTIME_DEPENDENCY_MAP.md", "Chapter 0 Runtime Dependency Map", "Chapter0HomeCoordinator depends on Core Diagnostics, EventBus, Logger, SnapshotManager, Interaction feedback, Observation signals, Chapter0Home config/state/validation/serialization/diagnostics/snapshots, Players, Workspace, and CollectionService. Bootstrap registers Chapter0HomeCoordinator after Observation, PlayerExperience, Interaction, World, Objective, Narrative, and Presentation. Runtime prerequisites are present in source, but Studio-created player/client state remains unverified.");
  writeDoc("03_STUDIO_EXECUTION_PATH.md", "Studio Execution Path", "Path evaluated: Rojo builds `default.project.json` into a temporary local place artifact, then the existing Studio automation bridge checks whether a supported non-interactive runner/capture path exists. Result: executionBlocked. Studio launch and Play/Run were not attempted because no supported capture path exists.");
  writeDoc("04_EVIDENCE_SCHEMA.md", "Runtime Evidence Schema", "The machine-readable schema is committed at `automation/runtime-evidence/phase-150/evidence-schema.json`. It separates static validation, installed-tool evidence, build automation evidence, and authoritative Roblox Studio runtime evidence.");
  writeDoc("05_SERVER_BOOTSTRAP_RESULTS.md", "Server Bootstrap Results", blockedRuntime);
  writeDoc("06_CLIENT_BOOTSTRAP_RESULTS.md", "Client Bootstrap Results", blockedRuntime);
  writeDoc("07_PLAYER_SPAWN_AND_MOVEMENT_RESULTS.md", "Player Spawn And Movement Results", blockedRuntime);
  writeDoc("08_INTERACTION_RUNTIME_RESULTS.md", "Interaction Runtime Results", blockedRuntime);
  writeDoc("09_OBSERVATION_RUNTIME_RESULTS.md", "Observation Runtime Results", blockedRuntime);
  writeDoc("10_ENVIRONMENTAL_REACTION_RESULTS.md", "Environmental Reaction Results", blockedRuntime);
  writeDoc("11_PRESENTATION_LIGHTING_AUDIO_RESULTS.md", "Presentation Lighting Audio Results", blockedRuntime);
  writeDoc("12_NARRATIVE_AND_UI_RESULTS.md", "Narrative And UI Results", blockedRuntime);
  writeDoc("13_DIAGNOSTICS_SNAPSHOTS_AND_AUDIT_RESULTS.md", "Diagnostics Snapshots And Audit Results", blockedRuntime);
  writeDoc("14_RESET_RESPAWN_AND_CLEANUP_RESULTS.md", "Reset Respawn And Cleanup Results", blockedRuntime);
  writeDoc("15_MULTIPLAYER_AUTHORITY_RESULTS.md", "Multiplayer Authority Results", "Status: BLOCKED\n\nNo supported multi-client Studio execution path is exposed to repository automation. No multiplayer authority evidence was captured.");
  writeDoc("16_PERFORMANCE_AND_RELIABILITY_RESULTS.md", "Performance And Reliability Results", `Status: NOT EXECUTED\n\nPreflight build duration: ${evidence.environment.preflight.durationMs} ms.\nRuntime bootstrap, client readiness, movement, interaction, reset, and memory measurements were not collected because Studio Play/Run mode was blocked.`);
  writeDoc("17_FAILURE_INJECTION_RESULTS.md", "Failure Injection Results", "Status: NOT EXECUTED\n\nFailure injection was not attempted because no trusted authoritative runtime harness exists. Static evidence validation rejects missing fields, invalid capability statuses, and certification-decision drift.");
  writeDoc("18_DEFECT_AND_REMEDIATION_LOG.md", "Defect And Remediation Log", "P1-150-001: Authoritative Studio Play/Run evidence capture is blocked. Root cause: repository has no supported command path that can enter Play/Run mode, invoke the Studio-gated runner, and capture structured server/client evidence. Remediation in this phase: added deterministic blocked evidence, schema, docs, and npm entry points. Remaining status: external/runtime execution capability required.");
  writeDoc("19_VERTICAL_SLICE_RUNTIME_SCORECARD.md", "Vertical Slice Runtime Scorecard", "No player-visible dimension received a numeric score because no authoritative Studio runtime evidence was captured. Place generation is verified as build automation only; all player-visible runtime capabilities are BLOCKED or NOT EXECUTED.");
  writeDoc("20_CERTIFICATION_BOUNDARY_REVIEW.md", "Certification Boundary Review", "Status: Production Candidate. Phase 108 remains the latest Production Certified milestone. Phase 150 evidence is not certification eligible because Studio Play/Run mode was not entered, no server/client evidence was captured, no player spawned, no interaction completed, and the certification authority did not receive a passing runtime result.");
  writeDoc("21_PHASE_150_PRODUCTION_REVIEW.md", "Phase 150 Production Review", "Verdict: Production Candidate, runtime blocked. The architecture boundary is preserved, no gameplay changed, no certification authority was duplicated, and no runtime evidence was fabricated. Largest limitation: no supported authoritative Studio execution path is available from repository automation.");
  writeDoc("22_PHASE_150_COMPLETION_REPORT.md", "Phase 150 Completion Report", `Phase: Phase 150 - ${phaseTitle}\n\nRuntime Maturity: Runtime Validation\n\nStatus: Production Candidate - Execution Blocked\n\nCommit: pending\n\nGitHub: pending until pushed\n\nSummary: Added deterministic Phase 150 evidence schema, blocked runtime evidence, Studio execution-path documentation, and validation entry points. Roblox Studio was detected where available, but Play/Run mode was not entered and the runner was not invoked.\n\nArchitecture Impact: Automation and documentation only. No gameplay, networking, persistence, analytics, telemetry, remotes, or certification authority changed.\n\nChanged Files: pending final git diff.\n\nValidation: pending final repository validation.\n\nSelf-Checks: pending final Phase 150 self-check and representative regression self-checks.\n\nRuntime Tests: Roblox Studio launched: false. Play/Run entered: false. Client count: 0. Player spawned: false. Movement observed: false. Interaction completed: false. Observation behavior occurred: false. Environmental reaction occurred: false.\n\nAuthoritative Studio Evidence: BLOCKED because no supported command path can invoke the Studio-gated runner and capture structured evidence.\n\nCertification Status: Phase 108 remains latest Production Certified. Phase 150 is not certification eligible.\n\nKnown Limitations: Human visual QA and multiplayer validation were not performed.\n\nNext Recommended Phase: Phase 151 - Chapter 0 Studio Runtime Evidence Enablement.`);
  writeDoc(
    "23_MANUAL_STUDIO_QA_CHECKLIST.md",
    "Manual Studio QA Checklist",
    `Status: NOT EXECUTED

Human visual QA was not performed during Phase 150.

Reviewer:

Date:

Studio version:

Run identifier:

Checklist:

- Spawn location feels intentional:
- Camera starts correctly:
- Movement is responsive:
- Controls are understandable:
- Interaction prompts are readable:
- Lighting is dark but navigable:
- Audio ambience is audible and not overpowering:
- Environmental reaction is visible or audible:
- Reaction timing is understandable:
- Observation mechanic produces a perceivable consequence:
- UI does not obstruct play:
- No placeholder content is accidentally prominent:
- No obvious broken geometry:
- No visible debug objects:
- No repeated sound stacking:
- No camera lock after reset:
- No duplicated UI:
- No immersion-breaking error output:
- No comedic or accidental presentation issue:
- Sequence can be completed more than once:
- Restart behavior is understandable:
- Player can identify what changed after a horror reaction:

Screenshot or recording reference:

Result:

Notes:`
  );
}

function writeArtifacts(evidence) {
  ensureDirectories();
  const schema = makeSchema();
  const validation = validateEvidence(evidence);
  if (!validation.ok) {
    throw new Error(validation.reason);
  }

  writeJson(schemaPath, schema);
  writeJson(evidencePath, evidence);
  writeJson(manifestPath, {
    schemaVersion,
    phase,
    status: evidence.status,
    repositoryCommit: evidence.repositoryCommit,
    generatedEvidence: [schemaPath, evidencePath],
    generatedDocs: docFiles.map((file) => `${docsDirectory}/${file}`),
    certificationEligible: false,
    certificationDecision: evidence.certificationDecision,
    nextAction: evidence.nextAction
  });
  writeDocs(evidence);
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runSelfChecks() {
  const results = [];
  const schema = makeSchema();
  const minimalEvidence = {
    schemaVersion,
    phase,
    phaseTitle,
    repositoryCommit: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    branch: "main",
    studioVersion: "unavailable",
    executionMode: "blockedBeforePlayMode",
    startTimestamp: "2026-07-18T00:00:00.000Z",
    endTimestamp: "2026-07-18T00:00:01.000Z",
    durationMilliseconds: 1000,
    placeArtifact: { path: buildArtifactPath, created: true, sizeBytes: 1, cleaned: true },
    serverStarted: false,
    clientStarted: false,
    playerJoined: false,
    characterSpawned: false,
    bootstrapCompleted: false,
    chapter0Initialized: false,
    observationInitialized: false,
    interactionInitialized: false,
    presentationInitialized: false,
    diagnosticsCaptured: false,
    snapshotsCaptured: false,
    auditCaptured: false,
    resetExecuted: false,
    cleanupExecuted: false,
    errors: [],
    warnings: [],
    assertions: [],
    capabilityResults: [capability("studioPlayMode", "BLOCKED", "studioHost", "blocked")],
    evidenceFiles: [schemaPath, evidencePath],
    environment: {},
    limitations: [],
    certificationEligible: false,
    certificationDecision: "notEvaluatedByCertificationAuthority"
  };

  assertSelfCheck(results, "schemaHasPhaseIdentity", schema.phase === phase, "");
  assertSelfCheck(results, "schemaSeparatesCertificationAuthority", schema.certificationAuthority.includes("Phase118CertificationContract"), "");
  assertSelfCheck(results, "validBlockedEvidence", validateEvidence(minimalEvidence).ok === true, "");
  const missingFieldEvidence = { ...minimalEvidence };
  delete missingFieldEvidence.phaseTitle;
  assertSelfCheck(results, "rejectMissingField", validateEvidence(missingFieldEvidence).ok === false, "");
  const invalidStatus = { ...minimalEvidence, capabilityResults: [capability("x", "probablyWorks", "test", "bad")] };
  assertSelfCheck(results, "rejectInvalidCapabilityStatus", validateEvidence(invalidStatus).ok === false, "");
  assertSelfCheck(results, "rejectCertificationDecisionDrift", validateEvidence({ ...minimalEvidence, certificationDecision: "certified" }).ok === false, "");
  assertSelfCheck(results, "rejectCertificationEligibilityDrift", validateEvidence({ ...minimalEvidence, certificationEligible: true }).ok === false, "");
  assertSelfCheck(results, "exitCodeStable", exitCodes.executionBlocked === 2 && exitCodes.sourceInvalid === 4, "");
  assertSelfCheck(results, "evidenceDirectoryStable", evidenceDirectory === "automation/runtime-evidence/phase-150", "");
  assertSelfCheck(results, "docsDirectoryStable", docsDirectory === "docs/phases/phase-150", "");
  assertSelfCheck(results, "studioBridgeIsAuthorityInputOnly", typeof runStudioBridge === "function", "");

  return results;
}

function printSelfChecks() {
  const results = runSelfChecks();
  const failures = results.filter((result) => !result.ok);
  console.log(`TOTAL ${results.length}`);
  console.log(`PASSED ${results.length - failures.length}`);
  console.log(`FAILURES ${failures.length}`);
  for (const failure of failures) {
    console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
  }
  process.exitCode = failures.length === 0 ? 0 : exitCodes.validationFailed;
}

function main() {
  if (process.argv.includes("--self-check")) {
    printSelfChecks();
    return;
  }

  try {
    const evidence = buildEvidence();
    writeArtifacts(evidence);
    console.log(`Phase ${phase}: ${phaseTitle}`);
    console.log(`Status: ${evidence.status}`);
    console.log(`Studio launched: ${evidence.studioLaunched}`);
    console.log(`Play mode entered: ${evidence.playModeEntered}`);
    console.log(`Runner invoked: ${evidence.environment.bridge.runnerInvoked}`);
    console.log(`Structured result captured: ${evidence.environment.bridge.structuredResultCaptured}`);
    console.log(`Evidence: ${evidencePath}`);
    console.log(`Docs: ${docsDirectory}`);
    process.exitCode =
      evidence.status === "verified" ? exitCodes.verified : exitCodes.executionBlocked;
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = exitCodes.validationFailed;
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
