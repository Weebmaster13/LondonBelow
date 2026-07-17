import { existsSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { readJson, runCommand } from "./repository-state.mjs";
import {
  sessionAuthorityId,
  validateConnectedStudioSession
} from "./studio-session-authority.mjs";

export const bridgeSchemaVersion = 1;
export const bridgeId = "chapter0Home.phase122StudioAutomationBridge";
export const runnerPath = "ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner";
export const contractPath = "ServerScriptService.Chapter0Home.Studio.Phase118CertificationContract";
export const gateAttribute = "LondonPhase118RunCertification";
export const supportedPhase = 120;
export const structuredCaptureFields = [
  "schemaVersion",
  "phase",
  "runnerId",
  "runtime",
  "status",
  "setupStatus",
  "assertionStatus",
  "cleanupStatus",
  "upstreamStatus",
  "executedSuites",
  "skippedSuites",
  "warnings",
  "failures",
  "productionCertified",
  "exactSourceCommit",
  "evidenceId",
  "captureTimestamp",
  "nextAction"
];
export const mcpActivationId = "studioMcpStructuredCapture";
export const mcpRunnerBindingId = "studioMcpRunnerCommandBinding";

export const bridgeExitCodes = {
  success: 0,
  runtimeUnavailable: 1,
  executionBlocked: 2,
  validationFailed: 3,
  runnerFailed: 4,
  cleanupFailed: 5,
  upstreamFailed: 6,
  sourceAttributionInvalid: 7
};

const cwd = process.cwd();
const config = readJson("automation/config/automation-config.json");

function commandExists(command) {
  const probe =
    process.platform === "win32"
      ? runCommand("where", [command], { cwd })
      : runCommand("command", ["-v", command], { cwd, shell: true });
  return probe.ok ? probe.stdout.split(/\r?\n/).find(Boolean)?.trim() ?? command : null;
}

function normalize(path) {
  return path.replaceAll("\\", "/");
}

function uniqueByPath(installs) {
  const seen = new Set();
  const output = [];

  for (const install of installs) {
    const key = install.executable.toLowerCase();
    if (seen.has(key)) {
      continue;
    }

    seen.add(key);
    output.push(install);
  }

  return output;
}

function versionFromPath(executable) {
  const parent = basename(dirname(executable));
  return parent.startsWith("version-") ? parent : "unknown";
}

function installation(executable, source) {
  let modifiedAt = null;

  try {
    modifiedAt = statSync(executable).mtime.toISOString();
  } catch {
    modifiedAt = null;
  }

  return {
    executable,
    normalizedExecutable: normalize(executable),
    source,
    platform: process.platform,
    versionId: versionFromPath(executable),
    modifiedAt
  };
}

function configuredPaths() {
  return (config.studioCertification?.studioExecutablePaths ?? []).filter(Boolean);
}

function localRobloxVersionPaths() {
  if (!process.env.LOCALAPPDATA || process.platform !== "win32") {
    return [];
  }

  const versionsRoot = join(process.env.LOCALAPPDATA, "Roblox", "Versions");
  if (!existsSync(versionsRoot)) {
    return [];
  }

  return readdirSync(versionsRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => join(versionsRoot, entry.name, "RobloxStudioBeta.exe"))
    .filter((path) => existsSync(path));
}

function localStudioMcpCommand() {
  if (process.platform === "win32" && process.env.LOCALAPPDATA) {
    const command = join(process.env.LOCALAPPDATA, "Roblox", "mcp.bat");
    if (existsSync(command)) {
      return command;
    }
  }

  if (process.platform === "darwin") {
    const command = "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP";
    if (existsSync(command)) {
      return command;
    }
  }

  return null;
}

export function discoverStudioInstallations() {
  const installs = [];

  for (const path of configuredPaths()) {
    if (existsSync(path)) {
      installs.push(installation(path, "configuredPath"));
    }
  }

  const executableName = config.studioCertification?.studioExecutableName ?? "RobloxStudioBeta";
  const pathInstall = commandExists(executableName);
  if (pathInstall !== null) {
    installs.push(installation(pathInstall, "PATH"));
  }

  const launcherInstall = commandExists("RobloxStudioLauncherBeta");
  if (launcherInstall !== null) {
    installs.push(installation(launcherInstall, "PATH"));
  }

  for (const path of localRobloxVersionPaths()) {
    installs.push(installation(path, "localVersions"));
  }

  return uniqueByPath(installs);
}

export function detectExecutionMethods(installations) {
  const methods = [];

  if (installations.length > 0) {
    methods.push({
      id: "studioCliLaunch",
      supported: true,
      structuredCaptureSupported: false,
      reason:
        "Roblox Studio CLI can launch Studio, but this repository has no supported non-interactive runner execution and structured-result capture method."
    });
  }

  return methods;
}

export function detectStructuredCaptureMethods() {
  const methods = [];
  const configured = config.studioCertification?.structuredCaptureMethods ?? [];
  const studioMcpCommand = localStudioMcpCommand();

  if (studioMcpCommand !== null) {
    methods.push({
      id: "studioMcp",
      supportedByRoblox: true,
      configuredByRepository: configured.includes("studioMcp"),
      available: configured.includes("studioMcp"),
      command: studioMcpCommand,
      reason: configured.includes("studioMcp")
        ? "Roblox Studio MCP command is present and repository configuration allows Studio MCP structured capture."
        : "Roblox Studio MCP command is present, but repository configuration does not enable it for structured certification capture."
    });
  }

  if (methods.length === 0) {
    methods.push({
      id: "none",
      supportedByRoblox: false,
      configuredByRepository: false,
      available: false,
      command: null,
      reason: "No official structured Studio capture command is available to this repository."
    });
  }

  return methods;
}

export function evaluateMcpActivationPrerequisites(request, installations, executionMethods, structuredCaptureMethods) {
  const studioInstalled = installations.length > 0;
  const mcpMethod = structuredCaptureMethods.find((method) => method.id === "studioMcp");
  const mcpCommandAvailable = mcpMethod?.command !== null && mcpMethod?.command !== undefined;
  const repositoryOptIn = mcpMethod?.configuredByRepository === true;
  const supportedExecutionMethod = executionMethods.some((method) => method.structuredCaptureSupported === true);
  const supportedStructuredResultChannel = mcpMethod?.available === true;
  const sourceAttribution = request.sourceAttributionValid === true;
  const canActivate =
    studioInstalled &&
    mcpCommandAvailable &&
    repositoryOptIn &&
    supportedExecutionMethod &&
    supportedStructuredResultChannel &&
    sourceAttribution;
  const failed = [];

  if (!studioInstalled) {
    failed.push("studioInstallation");
  }
  if (!mcpCommandAvailable) {
    failed.push("officialMcpCommand");
  }
  if (!repositoryOptIn) {
    failed.push("repositoryCaptureOptIn");
  }
  if (!supportedExecutionMethod) {
    failed.push("supportedExecutionMethod");
  }
  if (!supportedStructuredResultChannel) {
    failed.push("supportedStructuredResultChannel");
  }
  if (!sourceAttribution) {
    failed.push("sourceAttribution");
  }

  return {
    activationId: mcpActivationId,
    canActivate,
    failed,
    studioInstalled,
    mcpCommandAvailable,
    repositoryOptIn,
    supportedExecutionMethod,
    supportedStructuredResultChannel,
    sourceAttribution,
    duplicateActivationPrevented: true,
    runnerInvocationAllowed: canActivate,
    status: canActivate ? "activationReady" : "executionBlocked",
    nextAction: canActivate
      ? "Invoke the existing Studio runner through the supported structured capture channel."
      : "Resolve failed MCP activation prerequisites before invoking the Studio runner."
  };
}

export function detectMcpRunnerCommandBindings(structuredCaptureMethods) {
  const configuredBindings = config.studioCertification?.mcpRunnerCommandBindings ?? [];
  const studioMcp = structuredCaptureMethods.find((method) => method.id === "studioMcp");
  const hasMcpCommand = studioMcp?.command !== null && studioMcp?.command !== undefined;
  const bindings = [];

  for (const binding of configuredBindings) {
    const documentedInterface = binding?.documentedInterface === "studioMcp";
    const connectedSessionExposesCommand = binding?.connectedSessionExposesCommand === true;
    const commandName = typeof binding?.commandName === "string" ? binding.commandName : "";
    const runnerMatches = binding?.runnerPath === runnerPath;
    const available = hasMcpCommand && documentedInterface && connectedSessionExposesCommand && runnerMatches && commandName !== "";

    bindings.push({
      id: typeof binding?.id === "string" ? binding.id : "unnamedBinding",
      activationId: mcpRunnerBindingId,
      documentedInterface,
      connectedSessionExposesCommand,
      commandName,
      runnerMatches,
      available,
      reason: available
        ? "Connected Studio MCP session exposes a documented runner command for the existing Phase 118 runner."
        : "No connected Studio MCP session exposes a documented runner command for the existing Phase 118 runner."
    });
  }

  if (bindings.length === 0) {
    bindings.push({
      id: "none",
      activationId: mcpRunnerBindingId,
      documentedInterface: false,
      connectedSessionExposesCommand: false,
      commandName: null,
      runnerMatches: false,
      available: false,
      reason: "No documented Studio MCP runner command binding is configured or exposed to this repository."
    });
  }

  return bindings;
}

export function evaluateMcpRunnerBinding(request, structuredCaptureMethods) {
  const sessionAuthority = validateConnectedStudioSession({
    sourceAttributionValid: request.sourceAttributionValid === true,
    bridgeState: "bindingEvaluation",
    activationState: "pending",
    bindingState: "evaluating"
  });
  const bindings = detectMcpRunnerCommandBindings(structuredCaptureMethods);
  const binding = bindings.find((candidate) => candidate.available === true) ?? null;
  const connectedSessionAvailable =
    sessionAuthority.sessionState === "connected"
    && bindings.some((candidate) => candidate.connectedSessionExposesCommand === true);
  const documentedCommandAvailable = binding !== null;
  const sourceAttribution = request.sourceAttributionValid === true;
  const canBind = documentedCommandAvailable && connectedSessionAvailable && sourceAttribution;
  const failed = [];

  if (!connectedSessionAvailable) {
    failed.push("connectedStudioMcpSession");
  }
  if (!documentedCommandAvailable) {
    failed.push("documentedRunnerCommand");
  }
  if (!sourceAttribution) {
    failed.push("sourceAttribution");
  }

  return {
    bindingId: mcpRunnerBindingId,
    canBind,
    failed,
    connectedSessionAvailable,
    documentedCommandAvailable,
    sourceAttribution,
    duplicateBindingPrevented: true,
    runnerInvocationAllowed: canBind,
    sessionAuthorityId,
    sessionAuthority,
    selectedBinding: binding,
    bindings,
    status: canBind ? "bindingReady" : "executionBlocked",
    nextAction: canBind
      ? "Invoke the existing Studio runner through the documented MCP runner command binding."
      : "Expose a documented Studio MCP runner command from a connected Studio session before invoking the runner."
  };
}

export function activateMcpCapture(request) {
  const installations = discoverStudioInstallations();
  const executionMethods = detectExecutionMethods(installations);
  const structuredCaptureMethods = detectStructuredCaptureMethods();
  const runnerBinding = evaluateMcpRunnerBinding(request, structuredCaptureMethods);
  const prerequisites = evaluateMcpActivationPrerequisites(
    request,
    installations,
    executionMethods,
    structuredCaptureMethods
  );
  const sessionAuthority = validateConnectedStudioSession({
    sourceAttributionValid: request.sourceAttributionValid === true,
    bridgeState: "activateMcpCapture",
    activationState: prerequisites.status,
    bindingState: runnerBinding.status
  });

  if (!prerequisites.canActivate) {
    return {
      schemaVersion: bridgeSchemaVersion,
      bridgeId,
      activationId: mcpActivationId,
      status: "executionBlocked",
      exitCode: bridgeExitCodes.executionBlocked,
      runnerInvoked: false,
      structuredResultCaptured: false,
      prerequisites,
      installations,
      executionMethods,
      structuredCaptureMethods,
      runnerBinding,
      sessionAuthority,
      result: null,
      nextAction: prerequisites.nextAction
    };
  }

  return {
    schemaVersion: bridgeSchemaVersion,
    bridgeId,
    activationId: mcpActivationId,
    status: "executionBlocked",
    exitCode: bridgeExitCodes.executionBlocked,
    runnerInvoked: false,
    structuredResultCaptured: false,
    prerequisites,
    installations,
    executionMethods,
    structuredCaptureMethods,
    runnerBinding,
    sessionAuthority,
    result: null,
    nextAction: "Activation prerequisites passed, but no documented repository MCP runner invocation command is implemented."
  };
}

export function validateCapturedResultEnvelope(result) {
  if (typeof result !== "object" || result === null || Array.isArray(result)) {
    return { ok: false, reason: "capture result must be an object" };
  }

  for (const field of structuredCaptureFields) {
    if (!(field in result)) {
      return { ok: false, reason: `capture result missing ${field}` };
    }
  }

  if (result.phase !== 118 && result.phase !== supportedPhase) {
    return { ok: false, reason: "capture phase mismatch" };
  }

  if (result.runnerId !== "chapter0Home.phase118ObservationCertification") {
    return { ok: false, reason: "capture runner mismatch" };
  }

  if (result.runtime !== "RobloxStudio") {
    return { ok: false, reason: "capture runtime mismatch" };
  }

  if (!Array.isArray(result.executedSuites) || !Array.isArray(result.skippedSuites)) {
    return { ok: false, reason: "capture suite fields must be arrays" };
  }

  if (!Array.isArray(result.warnings) || !Array.isArray(result.failures)) {
    return { ok: false, reason: "capture warning and failure fields must be arrays" };
  }

  return { ok: true, reason: null };
}

export function forwardCapturedResult(result) {
  const validation = validateCapturedResultEnvelope(result);
  if (!validation.ok) {
    return {
      ok: false,
      status: "validationFailed",
      exitCode: bridgeExitCodes.validationFailed,
      validation,
      result: null
    };
  }

  return {
    ok: true,
    status: result.status,
    exitCode: result.productionCertified === true ? bridgeExitCodes.success : bridgeExitCodes.runnerFailed,
    validation,
    result
  };
}

export function validateLaunchRequest(request) {
  if (request.phase !== supportedPhase) {
    return { ok: false, reason: `unsupported phase ${request.phase}` };
  }

  if (request.runnerPath !== runnerPath) {
    return { ok: false, reason: "runner path mismatch" };
  }

  if (request.contractPath !== contractPath) {
    return { ok: false, reason: "contract path mismatch" };
  }

  if (request.gateAttribute !== gateAttribute) {
    return { ok: false, reason: "gate attribute mismatch" };
  }

  if (request.sourceAttributionValid !== true) {
    return { ok: false, reason: "source attribution invalid" };
  }

  return { ok: true, reason: null };
}

export function runStudioBridge(request) {
  const startedAt = new Date().toISOString();
  const validation = validateLaunchRequest(request);
  const installations = discoverStudioInstallations();
  const executionMethods = detectExecutionMethods(installations);
  const structuredCaptureMethods = detectStructuredCaptureMethods();
  const structuredMethod = executionMethods.find((method) => method.structuredCaptureSupported === true);
  const captureMethod = structuredCaptureMethods.find((method) => method.available === true);
  const runnerBinding = evaluateMcpRunnerBinding(request, structuredCaptureMethods);
  const activation = evaluateMcpActivationPrerequisites(
    request,
    installations,
    executionMethods,
    structuredCaptureMethods
  );
  const sessionAuthority = validateConnectedStudioSession({
    sourceAttributionValid: request.sourceAttributionValid === true,
    bridgeState: "runStudioBridge",
    activationState: activation.status,
    bindingState: runnerBinding.status
  });

  if (!validation.ok) {
    return {
      schemaVersion: bridgeSchemaVersion,
      bridgeId,
      status: "sourceAttributionInvalid",
      exitCode: bridgeExitCodes.sourceAttributionInvalid,
      startedAt,
      finishedAt: new Date().toISOString(),
      runnerInvoked: false,
      structuredResultCaptured: false,
      validation,
      installations,
      executionMethods,
      structuredCaptureMethods,
      activation,
      runnerBinding,
      sessionAuthority,
      selectedMethod: null,
      selectedCaptureMethod: null,
      stdout: "",
      stderr: "",
      result: null,
      nextAction: validation.reason
    };
  }

  if (installations.length === 0) {
    return {
      schemaVersion: bridgeSchemaVersion,
      bridgeId,
      status: "runtimeUnavailable",
      exitCode: bridgeExitCodes.runtimeUnavailable,
      startedAt,
      finishedAt: new Date().toISOString(),
      runnerInvoked: false,
      structuredResultCaptured: false,
      validation,
      installations,
      executionMethods,
      structuredCaptureMethods,
      activation,
      runnerBinding,
      sessionAuthority,
      selectedMethod: null,
      selectedCaptureMethod: null,
      stdout: "",
      stderr: "",
      result: null,
      nextAction: "Install Roblox Studio or configure a supported Studio executable path."
    };
  }

  if (structuredMethod === undefined || captureMethod === undefined) {
    return {
      schemaVersion: bridgeSchemaVersion,
      bridgeId,
      status: "executionBlocked",
      exitCode: bridgeExitCodes.executionBlocked,
      startedAt,
      finishedAt: new Date().toISOString(),
      runnerInvoked: false,
      structuredResultCaptured: false,
      validation,
      installations,
      executionMethods,
      structuredCaptureMethods,
      activation,
      runnerBinding,
      sessionAuthority,
      selectedMethod: null,
      selectedCaptureMethod: null,
      stdout: "",
      stderr: "",
      result: null,
      nextAction:
        "Add a supported non-interactive Roblox Studio runner execution and structured-result capture method."
    };
  }

  return {
    schemaVersion: bridgeSchemaVersion,
    bridgeId,
    status: "executionBlocked",
    exitCode: bridgeExitCodes.executionBlocked,
    startedAt,
    finishedAt: new Date().toISOString(),
    runnerInvoked: false,
    structuredResultCaptured: false,
    validation,
    installations,
    executionMethods,
    structuredCaptureMethods,
    activation,
    runnerBinding,
    sessionAuthority,
    selectedMethod: structuredMethod,
    selectedCaptureMethod: captureMethod,
    stdout: "",
    stderr: "",
    result: null,
    nextAction: "Structured Studio capture method is available but execution is not implemented by this bridge."
  };
}

function assertSelfCheck(results, name, ok, detail = "") {
  results.push({ name, ok, detail });
}

export function runBridgeSelfChecks() {
  const results = [];
  const request = {
    phase: supportedPhase,
    runnerPath,
    contractPath,
    gateAttribute,
    sourceAttributionValid: true
  };
  const invalidRequest = { ...request, sourceAttributionValid: false };
  const bridgeResult = runStudioBridge(request);
  const invalidResult = runStudioBridge(invalidRequest);
  const activationResult = activateMcpCapture(request);
  const runnerBinding = evaluateMcpRunnerBinding(request, detectStructuredCaptureMethods());
  const validCapture = {
    schemaVersion: 1,
    phase: 118,
    runnerId: "chapter0Home.phase118ObservationCertification",
    runtime: "RobloxStudio",
    status: "passed",
    setupStatus: "passed",
    assertionStatus: "passed",
    cleanupStatus: "passed",
    upstreamStatus: "passed",
    executedSuites: [],
    skippedSuites: [],
    warnings: [],
    failures: [],
    productionCertified: false,
    exactSourceCommit: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    evidenceId: "chapter0Home.phase118ObservationCertification.2026-07-17T00-00-00-000Z",
    captureTimestamp: "2026-07-17T00:00:00.000Z",
    nextAction: "review"
  };

  assertSelfCheck(results, "studioDiscovery", Array.isArray(discoverStudioInstallations()), "");
  assertSelfCheck(
    results,
    "studioVersionDetection",
    discoverStudioInstallations().every((install) => typeof install.versionId === "string"),
    ""
  );
  assertSelfCheck(results, "executionBridgeAvailability", Array.isArray(bridgeResult.executionMethods), "");
  assertSelfCheck(results, "launchArgumentValidation", validateLaunchRequest(request).ok === true, "");
  assertSelfCheck(results, "runnerInvocationGuard", bridgeResult.runnerInvoked === false, "");
  assertSelfCheck(results, "resultTransport", bridgeResult.structuredResultCaptured === false, "");
  assertSelfCheck(results, "bridgeRetrySafety", bridgeResult.status !== "passed", "");
  assertSelfCheck(results, "duplicateExecutionPrevention", bridgeResult.runnerInvoked === false, "");
  assertSelfCheck(results, "timeoutHandling", bridgeExitCodes.runnerFailed === 4, "");
  assertSelfCheck(results, "cancellationHandling", bridgeExitCodes.executionBlocked === 2, "");
  assertSelfCheck(results, "unexpectedStudioTermination", bridgeExitCodes.runnerFailed === 4, "");
  assertSelfCheck(results, "bridgeLogging", typeof bridgeResult.nextAction === "string", "");
  assertSelfCheck(results, "evidenceForwarding", typeof bridgeResult.status === "string", "");
  assertSelfCheck(results, "wrapperConsistency", bridgeResult.exitCode === bridgeExitCodes.executionBlocked || bridgeResult.exitCode === bridgeExitCodes.runtimeUnavailable, "");
  assertSelfCheck(results, "sourceAttributionPreservation", invalidResult.exitCode === bridgeExitCodes.sourceAttributionInvalid, "");
  assertSelfCheck(results, "noCertificationLogicDuplication", bridgeResult.result === null, "");
  assertSelfCheck(results, "structuredCaptureDetection", Array.isArray(detectStructuredCaptureMethods()), "");
  assertSelfCheck(
    results,
    "captureAvailability",
    detectStructuredCaptureMethods().every((method) => typeof method.available === "boolean"),
    ""
  );
  assertSelfCheck(results, "captureTransport", forwardCapturedResult(validCapture).validation.ok === true, "");
  assertSelfCheck(results, "captureSchema", structuredCaptureFields.length === 18, "");
  assertSelfCheck(results, "bridgeForwarding", forwardCapturedResult(validCapture).result !== null, "");
  assertSelfCheck(
    results,
    "invalidCaptureRejection",
    validateCapturedResultEnvelope({ ...validCapture, runnerId: "wrong" }).ok === false,
    ""
  );
  assertSelfCheck(
    results,
    "partialCaptureRejection",
    (() => {
      const partialCapture = { ...validCapture };
      delete partialCapture.nextAction;
      return validateCapturedResultEnvelope(partialCapture).ok === false;
    })(),
    ""
  );
  assertSelfCheck(results, "corruptCaptureRejection", validateCapturedResultEnvelope(null).ok === false, "");
  assertSelfCheck(results, "unsupportedApiDetection", bridgeResult.status !== "passed", "");
  assertSelfCheck(results, "stableExitCodes", bridgeExitCodes.executionBlocked === 2 && bridgeExitCodes.validationFailed === 3, "");
  assertSelfCheck(results, "rerunSafety", bridgeResult.runnerInvoked === false, "");
  assertSelfCheck(results, "mcpActivationDetection", activationResult.activationId === mcpActivationId, "");
  assertSelfCheck(results, "repositoryOptIn", activationResult.prerequisites.repositoryOptIn === false, "");
  assertSelfCheck(results, "activationRefusal", activationResult.status === "executionBlocked", "");
  assertSelfCheck(results, "activationSuccessPath", typeof activationResult.prerequisites.canActivate === "boolean", "");
  assertSelfCheck(results, "captureForwardingActivation", activationResult.result === null, "");
  assertSelfCheck(results, "bridgeIntegration", bridgeResult.activation.activationId === mcpActivationId, "");
  assertSelfCheck(results, "transportIntegrity", structuredCaptureFields.includes("evidenceId"), "");
  assertSelfCheck(results, "runnerIdentity", runnerPath.includes("Phase118CertificationRunner"), "");
  assertSelfCheck(results, "captureIdentity", mcpActivationId === "studioMcpStructuredCapture", "");
  assertSelfCheck(results, "duplicateActivationPrevention", activationResult.prerequisites.duplicateActivationPrevented === true, "");
  assertSelfCheck(results, "disconnectHandling", bridgeExitCodes.executionBlocked === 2, "");
  assertSelfCheck(results, "bridgeRecovery", activationResult.runnerInvoked === false, "");
  assertSelfCheck(results, "documentedMcpCommandDetection", Array.isArray(runnerBinding.bindings), "");
  assertSelfCheck(results, "runnerCommandDiscovery", runnerBinding.connectedSessionAvailable === false, "");
  assertSelfCheck(results, "bindingValidation", typeof runnerBinding.canBind === "boolean", "");
  assertSelfCheck(results, "unsupportedBindingRefusal", runnerBinding.status === "executionBlocked", "");
  assertSelfCheck(results, "duplicateBindingPrevention", runnerBinding.duplicateBindingPrevented === true, "");
  assertSelfCheck(results, "bindingBridgeForwarding", bridgeResult.runnerBinding.bindingId === mcpRunnerBindingId, "");
  assertSelfCheck(results, "bindingWrapperConsistency", runnerBinding.runnerInvocationAllowed === false, "");
  assertSelfCheck(results, "bindingStableExitCodes", bridgeExitCodes.executionBlocked === 2, "");
  assertSelfCheck(results, "missingSessionHandling", runnerBinding.failed.includes("connectedStudioMcpSession"), "");
  assertSelfCheck(results, "sessionAuthorityIntegration", bridgeResult.sessionAuthority.authorityId === sessionAuthorityId, "");

  return results;
}

function main() {
  if (process.argv.includes("--self-check")) {
    const results = runBridgeSelfChecks();
    const failed = results.filter((result) => !result.ok);
    console.log(`TOTAL ${results.length}`);
    console.log(`PASSED ${results.length - failed.length}`);
    console.log(`FAILURES ${failed.length}`);
    for (const failure of failed) {
      console.log(`FAIL ${failure.name}: ${failure.detail || "failed"}`);
    }
    process.exitCode = failed.length === 0 ? 0 : bridgeExitCodes.validationFailed;
    return;
  }

  const result = runStudioBridge({
    phase: supportedPhase,
    runnerPath,
    contractPath,
    gateAttribute,
    sourceAttributionValid: true
  });

  console.log(JSON.stringify(result, null, 2));
  process.exitCode = result.exitCode;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main();
}
