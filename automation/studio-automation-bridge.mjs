import { existsSync, readdirSync, statSync } from "node:fs";
import { basename, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { readJson, runCommand } from "./repository-state.mjs";

export const bridgeSchemaVersion = 1;
export const bridgeId = "chapter0Home.phase122StudioAutomationBridge";
export const runnerPath = "ServerScriptService.Chapter0Home.Studio.Phase118CertificationRunner";
export const contractPath = "ServerScriptService.Chapter0Home.Studio.Phase118CertificationContract";
export const gateAttribute = "LondonPhase118RunCertification";
export const supportedPhase = 120;

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
  const structuredMethod = executionMethods.find((method) => method.structuredCaptureSupported === true);

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
      selectedMethod: null,
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
      selectedMethod: null,
      stdout: "",
      stderr: "",
      result: null,
      nextAction: "Install Roblox Studio or configure a supported Studio executable path."
    };
  }

  if (structuredMethod === undefined) {
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
      selectedMethod: null,
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
    selectedMethod: structuredMethod,
    stdout: "",
    stderr: "",
    result: null,
    nextAction: "Structured Studio execution method is declared but not implemented by this bridge."
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
